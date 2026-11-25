Zadanie 1:


maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % curl http://localhost:5001/health
{"status":"ok"}
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker logs backend
Wczytano 89 hashy z /app/data/leaked-sha1.txt
 * Serving Flask app 'app'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://172.18.0.2:5000
Press CTRL+C to quit
192.168.65.1 - - [13/Nov/2026 13:40:11] "GET /health HTTP/1.1" 200 -
192.168.65.1 - - [13/Nov/2026 13:41:17] "GET /health HTTP/1.1" 200 -
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % 


Zadanie 2:

maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker run --rm --network breach-net healthcheck-probe
backend: OK
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker run --rm healthcheck-probe
backend: UNREACHABLE
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker stop backend
backend
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker run --rm --network breach-net healthcheck-probe
backend: UNREACHABLE
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker start backend
backend
maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % 


dlaczego bez `--network` nazwa `backend` nie działa, choć kontener jest uruchomiony?
Domyślna sieć bridge w Dockerze nie posiada wbudowanego serwera DNS pozwalającego na rozwiązywanie nazw kontenerów na ich adresy IP. Automatyczne tłumaczenie nazw kontenerów działa wyłącznie w sieciach utworzonych ręcznie przez użytkownika, dlatego bez flagi --network breach-net sonda nie wie, pod jakim adresem szukać hosta backend.


Zadanie 3:

maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker exec backend cat /tmp/notatka.txt
notatka

maksymilianfikus@MacBook-Air-Maksymilian metody-wirtualizacji-laboratoria-pliki-4 % docker exec backend cat /tmp/notatka.txt
cat: /tmp/notatka.txt: No such file or directory


historia.txt:
Fri Nov 13 13:45:10 UTC 2026
Fri Nov 13 13:45:15 UTC 2026

Wyjaśnienie:
Plik w tmp powstał w warstwie zapisywalnej kontenera, która jest zachowywana podczas zwykłego zatrzymania i docker restart, ale zostaje trwale skasowana wraz z usunięciem kontenera docker rm. Plik historia.txt przetrwał, ponieważ zapisano go w nazwanym wolumenie Dockera breach-dane, który istnieje niezależnie od cyklu życia samych kontenerów. Lista wycieków również przetrwałaby polecenie docker rm, ponieważ jest zamontowana z dysku hosta za pomocą bind mount, więc jej źródło znajduje się poza kontenerem.

