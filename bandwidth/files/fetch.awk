{
    if (FILENAME == neighfile)
    {
        # There can only be one MAC per IP.
        ip2mac[$1] = $2

        # There can be several IP per MAC so we only take the first one
        if (!($2 in mac2ip))
        {
            mac2ip[$2] = $1
        }
    }

    else if (FILENAME == leasefile)
    {
        mac2hostname[$2] = $4
    }

    else if (FILENAME == txfile && FNR > 2)
    {
        tx[ip2mac[$8]] += $2
    }

    else if (FILENAME == rxfile && FNR > 2)
    {
        rx[ip2mac[$9]] += $2
    }
}

END
{
    if (json)
    {
        first = 1
        print "["
        for (mac in tx)
        {
            if (!first)
            {
                print ","
            }
            else
            {
                first = 0
            }
            print "{"
            print "\"mac\": \""mac"\","
            print "\"ip\": \""mac2ip[mac]"\","
            print "\"hostname\": \""mac2hostname[mac]"\","
            print "\"tx\": "tx[mac]","
            print "\"rx\": "rx[mac]
            print "}"
        }
        print "]"
    }
    else
    {
        for (mac in tx)
        {
            print mac, tx[mac], rx[mac]
        }
    }
}
