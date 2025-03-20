# Computer Networks I 

cn1rout VM: deze VM maakt een NAT router tussen ... 
* enerzijds de eth0/VBox-NAT -> WAN side to Internet
* eth1 bridged naar de NIC van de host -> LAN voor een random ingeplugde switch
Let wel: om te voorkomen dat de Windows NIC ook een IP krijgt van deze range (en de NAT hierdoor in een loop komt), moet je jouw MAC-adres van deze NIC toevoegen aan de ignore lijst van DNSmasq.
