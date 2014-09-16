/**
 * 
 * Revised from
 * http://stackoverflow.com/questions/17516548/determining-the-current-link-speed-of-wifi-in-c-sharp
 * 
 * */
using System;
using System.Threading;
using System.Linq;
using System.Runtime.InteropServices;

class Program
{
    /*
     * System.Net.NetworkInformation.NetworkInterface would  not give you actual link speed
     * See
     * http://msdn.microsoft.com/en-us/library/system.net.networkinformation.networkinterface%28v=vs.110%29.aspx
     * */
    private static void Main(string[] args)
    {
        Console.WriteLine("GetAdaptersAddresses yields: ");
        DisplayWiFiAddresses();

        Console.WriteLine("\nGetAllNetworkInterfaces yields: ");
        DisplayWiFIInterface();
    }

    private static void DisplayWiFiAddresses()
    {
        string[] nameSearches = { "Wireless", "WiFi", "802.11", "Wi-Fi" };

        // AF_INET for IPv4, AF_INET6 for IPv6, and `AF_UNSPEC` for both
        foreach (IPIntertop.IP_ADAPTER_ADDRESSES net in IPIntertop.GetIPAdapters(IPIntertop.FAMILY.AF_UNSPEC))
        {
            bool containsName = false;
            foreach (string name in nameSearches)
            {
                if (net.FriendlyName.Contains(name))
                {
                    containsName = true;
                }
            }
            if (!containsName) continue;

            Alignment alignment = new Alignment(net.Alignment);

            Console.WriteLine("\tLength of the IP_ADAPTER_ADDRESS struct: " + alignment.Length);
            Console.WriteLine("\tIfIndex (IPv4 interface): " + alignment.IfIndex);
            Console.WriteLine("\tAdapter name: " + Marshal.PtrToStringAnsi(net.AdapterName));
            Console.WriteLine("\tDNS Suffix: " + net.DnsSuffix);
            Console.WriteLine("\tDescription: " + net.Description);
            Console.WriteLine("\tFriendly name: " + net.FriendlyName);

            if (net.PhysicalAddressLength != 0)
            {
                Console.WriteLine("\tPhysical address: " + BitConverter.ToString(net.PhysicalAddress.Take((int)net.PhysicalAddressLength).ToArray()));
            }
            Console.WriteLine("\tFlags: " + net.Flags);
            Console.WriteLine("\tMtu: " + net.Mtu);
            Console.WriteLine("\tIfType: " + net.IfType);
            Console.WriteLine("\tOperStatus: " + net.OperStatus);

            Console.WriteLine("\tIpv6IfIndex (IPv6 interface): " + net.Ipv6IfIndex);

            Console.Write("\tZoneIndices (hex): ");
            for (int i = 0; i < net.ZoneIndices.Length; i++)
            {
                Console.Write(net.ZoneIndices[i].ToString("X") + " ");
            }
            Console.WriteLine("");

            Console.WriteLine("\tTransmit link speed: " + net.TransmitLinkSpeed);
            Console.WriteLine("\tReceive link speed: " + net.ReceiveLinkSpeed);

            IntPtr prefix = net.FirstPrefix;
            int counter = 0;
            for (int i = 0; prefix != IntPtr.Zero; i++)
            {
                IPIntertop.IP_ADAPTER_PREFIX tmp;
                tmp = (IPIntertop.IP_ADAPTER_PREFIX)Marshal.PtrToStructure(prefix, typeof(IPIntertop.IP_ADAPTER_PREFIX));
                prefix = tmp.Next;
                counter++;
            }
            Console.WriteLine("\tNumber of IP Adapter Prefix entries: " + counter);

            Console.WriteLine("");
        }
    }

    private class Alignment
    {
        public uint Length;
        public uint IfIndex;

        public Alignment(UInt64 alignment)
        {
            byte[] bytes = BitConverter.GetBytes(alignment);
            Length = BitConverter.ToUInt32(bytes, 0);
            IfIndex = BitConverter.ToUInt32(bytes, 4);
        }
    }

    private static void DisplayWiFIInterface()
    {

        System.Net.NetworkInformation.NetworkInterface[] nics = null;
        nics = System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces();
        foreach (System.Net.NetworkInformation.NetworkInterface net in nics)
        {
            if (net.Name.Contains("Wireless") || net.Name.Contains("WiFi") || net.Name.Contains("802.11") || net.Name.Contains("Wi-Fi"))
            {
                Console.WriteLine("\tCurrent Wi-Fi Speed on " + net.Description + ": " + net.Speed + "\n");
            }
        }
    }
}

