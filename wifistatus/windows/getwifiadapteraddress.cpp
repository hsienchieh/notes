/**
 *
 * Revised from the sample program
 * at http://msdn.microsoft.com/en-us/library/windows/desktop/aa365915%28v=vs.85%29.aspx
 * the reference to GetAdaptersAddresses function
 *
 * */
#include <winsock2.h>
#include <iphlpapi.h>
#include <stdio.h>
#include <stdlib.h>

// Link with Iphlpapi.lib
#pragma comment(lib, "IPHLPAPI.lib")

#define WORKING_BUFFER_SIZE 15000
#define MAX_TRIES 3

#define MALLOC(x) HeapAlloc(GetProcessHeap(), 0, (x))
#define FREE(x) HeapFree(GetProcessHeap(), 0, (x))

/* Note: could also use malloc() and free() */

static DWORD getAdapterAddresses(PIP_ADAPTER_ADDRESSES *p2pAddresses);
static void printWiFiAddresses(PIP_ADAPTER_ADDRESSES *p2pAddresses);
static void cleanup(DWORD dwRetVal, PIP_ADAPTER_ADDRESSES *p2pAddresses);
static int isWiFi(PWCHAR name);

int __cdecl main(void)
{

	/* Declare and initialize variables */
	DWORD dwRetVal = 0;

	PIP_ADAPTER_ADDRESSES pAddresses = NULL;

	dwRetVal = getAdapterAddresses(&pAddresses);

	if (dwRetVal == NO_ERROR) {
		printWiFiAddresses(&pAddresses);
	}

	cleanup(dwRetVal, &pAddresses);

	return 0;
}

static DWORD getAdapterAddresses(PIP_ADAPTER_ADDRESSES *p2pAddresses) {

	// Allocate a 15 KB buffer to start with.
	ULONG outBufLen = WORKING_BUFFER_SIZE;;
	ULONG Iterations = 0;
	DWORD dwRetVal = 0;

	// default to unspecified address family (both IPv4 and IPv6)
	ULONG family = AF_UNSPEC;

	// Set the flags to pass to GetAdaptersAddresses
	ULONG flags = GAA_FLAG_INCLUDE_PREFIX;

	// Try MAX_TRIES time with new buffer size if buffer is too small 
	do {

		*p2pAddresses = (IP_ADAPTER_ADDRESSES *)MALLOC(outBufLen);
		if (*p2pAddresses == NULL) {
			printf
				("Memory allocation failed for IP_ADAPTER_ADDRESSES struct\n");
			exit(1);
		}

		dwRetVal =
			GetAdaptersAddresses(family, flags, NULL, *p2pAddresses, &outBufLen);

		if (dwRetVal == ERROR_BUFFER_OVERFLOW) {
			FREE(*p2pAddresses);
			*p2pAddresses = NULL;
		}
		else {
			break;
		}

		Iterations++;

	} while ((dwRetVal == ERROR_BUFFER_OVERFLOW) && (Iterations < MAX_TRIES));

	return dwRetVal;
}

static void printWiFiAddresses(PIP_ADAPTER_ADDRESSES *p2pAddresses) {
	unsigned int i = 0;
	IP_ADAPTER_PREFIX *pPrefix = NULL;

	PIP_ADAPTER_ADDRESSES pCurrAddresses = *p2pAddresses;

	// If successful, output some information from the data we received
	while (pCurrAddresses) {

		if (!isWiFi(pCurrAddresses->FriendlyName)) {
			pCurrAddresses = pCurrAddresses->Next;
			continue;
		}


		printf("\tLength of the IP_ADAPTER_ADDRESS struct: %ld\n",
			pCurrAddresses->Length);
		printf("\tIfIndex (IPv4 interface): %u\n", pCurrAddresses->IfIndex);
		printf("\tAdapter name: %s\n", pCurrAddresses->AdapterName);

		printf("\tDNS Suffix: %wS\n", pCurrAddresses->DnsSuffix);
		printf("\tDescription: %wS\n", pCurrAddresses->Description);
		printf("\tFriendly name: %wS\n", pCurrAddresses->FriendlyName);

		if (pCurrAddresses->PhysicalAddressLength != 0) {
			printf("\tPhysical address: ");
			for (i = 0; i < (int)pCurrAddresses->PhysicalAddressLength;
				i++) {
				if (i == (pCurrAddresses->PhysicalAddressLength - 1))
					printf("%.2X\n",
					(int)pCurrAddresses->PhysicalAddress[i]);
				else
					printf("%.2X-",
					(int)pCurrAddresses->PhysicalAddress[i]);
			}
		}
		printf("\tFlags: %ld\n", pCurrAddresses->Flags);
		printf("\tMtu: %lu\n", pCurrAddresses->Mtu);
		printf("\tIfType: %ld\n", pCurrAddresses->IfType);
		printf("\tOperStatus: %ld\n", pCurrAddresses->OperStatus);
		printf("\tIpv6IfIndex (IPv6 interface): %u\n",
			pCurrAddresses->Ipv6IfIndex);
		printf("\tZoneIndices (hex): ");
		for (i = 0; i < 16; i++)
			printf("%lx ", pCurrAddresses->ZoneIndices[i]);
		printf("\n");

		printf("\tTransmit link speed: %I64u\n", pCurrAddresses->TransmitLinkSpeed);
		printf("\tReceive link speed: %I64u\n", pCurrAddresses->ReceiveLinkSpeed);

		pPrefix = pCurrAddresses->FirstPrefix;
		for (i = 0; pPrefix != NULL; i++)
			pPrefix = pPrefix->Next;
		printf("\tNumber of IP Adapter Prefix entries: %d\n", i);

		printf("\n");

		pCurrAddresses = pCurrAddresses->Next;
	}
}

static void cleanup(DWORD dwRetVal, PIP_ADAPTER_ADDRESSES *p2pAddresses) {
	if (*p2pAddresses) {
		FREE(*p2pAddresses);
	}

	if (dwRetVal == NO_ERROR) {
		return;
	}

	printf("Call to GetAdaptersAddresses failed with error: %d\n",
		dwRetVal);
	if (dwRetVal == ERROR_NO_DATA)
		printf("\tNo addresses were found for the requested parameters\n");
	else {
		LPVOID lpMsgBuf = NULL;

		if (FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
			FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL, dwRetVal, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
			// Default language
			(LPTSTR)& lpMsgBuf, 0, NULL)) {
			printf("\tError: %s", lpMsgBuf);
			LocalFree(lpMsgBuf);
			exit(1);
		}
	}
}

static int isWiFi(PWCHAR name) {
	PWCHAR namesToSearch[] = { L"Wireless", L"WiFi", L"802.11", L"Wi-Fi" };

	for (int i = 0; i < sizeof(namesToSearch) / sizeof(PWCHAR); i++) {
		if (wcsstr(name, namesToSearch[i]) != NULL) {
			return 1;
		}
	}

	return 0;
}
