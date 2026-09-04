FROM squidfunk/mkdocs-material:9.5.34 AS builder
WORKDIR /app
COPY portal/mkdocs.yml /app/
COPY portal/docs /app/docs
COPY portal/scripts/stage-content.py /app/stage-content.py
COPY training-content /training-content
RUN python /app/stage-content.py /training-content /app/docs
RUN mkdocs build --clean

FROM nginx:1.27-alpine
COPY --from=builder /app/site /usr/share/nginx/html
COPY --from=builder /app/course-access.map /etc/nginx/course-access.map
COPY portal/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
