#!/bin/sh
#  r2
# 1 Удаление всех правил в таблице "filter" (по умолчанию)
iptables -F
iptables -X

# 2 Удаление правил в таблице «NAT»
iptables -F -t nat
# 3 Отбрасывать все маршрутизируемые пакеты
iptables --policy FORWARD DROP

# 4 Разрешить маршрутизацию всех пакетов протокола **ICMP**
iptables -A FORWARD -p icmp -j ACCEPT

# 5 **SNAT**, Маскирование локальной сети 10.20.0.0/26
# Подменяем источник для пакетов из внутренней сети
iptables -t nat -A POSTROUTING -s 10.20.0.0/26 -j MASQUERADE
# Разрешить пересылку пакетов ИЗ внутренней сети наружу
iptables -A FORWARD -s 10.20.0.0/26 -j ACCEPT
# Разрешить пересылку пакетов с установленным соединением обратно
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# 6) DNAT: Перенаправление порта 8080 на ws22:80
# Когда кто-то подключается к r2:8080, перенаправляем на ws22:80
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.20.0.20:80

# Разрешить пересылку для DNAT
iptables -A FORWARD -p tcp -d 10.20.0.20 --dport 80 -j ACCEPT




# Открытие портов  22(SSH) и 80(HTTP)
#iptables -A INPUT -p tcp --dport 22 -j ACCEPT
#iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Разрешение echo_reply(ICMP) - Ping
#iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT