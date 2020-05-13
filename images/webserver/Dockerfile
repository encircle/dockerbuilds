FROM nginx:1.17.9-alpine
RUN ln -s -f /dev/null /root/.bash_history
RUN addgroup nginx www-data
RUN mkdir /etc/nginx/encircle.d
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/encircle.d/cloudflare.conf /etc/nginx/encircle.d/cloudflare.conf
COPY conf/nginx/encircle.d/encircle.conf /etc/nginx/encircle.d/encircle.conf
