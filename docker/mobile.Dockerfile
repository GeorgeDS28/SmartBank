# Flutter web build
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY mobile/pubspec.* ./

RUN flutter pub get

COPY mobile/ .

RUN flutter build web


# Serve Flutter web application
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

