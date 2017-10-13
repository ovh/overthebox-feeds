function unitify (value, return_array)
{
    if (value >= 1000000000000)
    {
        return_array["val"] =  (value / 1000000000000)
        return_array["unit"] = "T"
    }
    else if (value >= 1000000000)
    {
        return_array["val"] =  (value / 1000000000)
        return_array["unit"] = "G"
    }
    else if (value >= 1000000)
    {
        return_array["val"] =  (value / 1000000)
        return_array["unit"] = "M"
    }
    else if (value >= 1000)
    {
        return_array["val"] =  (value / 1000)
        return_array["unit"] = "k"
    }
    else
    {
        return_array["val"] = value
        return_array["unit"] = ""
    }
}

{
    if (FILENAME == traffile".new")
    {
        tx[$1] = $2
        rx[$1] = $3
    }

    else if (FILENAME == traffile)
    {
        tx[$1] = (tx[$1] - $2) / interval
        rx[$1] = (rx[$1] - $3) / interval
    }
}
END
{
    printf "%7s%s%7s %4s%s%5s %4s%s\n", "", "MAC", "", "", "TX", "", "", "RX"
    for (mac in tx)
    {
        if (tx[mac] >= 0 && rx[mac] >= 0)
        {
            unitify(tx[mac], tx_res)
            unitify(rx[mac], rx_res)
            printf "%s %6.2f %1sB/s %6.2f %1sB/s\n", mac, tx_res["val"], tx_res["unit"], rx_res["val"], rx_res["unit"]
        }
        else
        {
            print mac, "waiting for data..."
        }
    }
}
