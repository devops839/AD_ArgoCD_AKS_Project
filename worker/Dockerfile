# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
ENV BUILDPLATFORM="linux/amd64"
ENV TARGETPLATFORM="linux/amd64"
ENV TARGETARCH="x86_64"

WORKDIR /source
COPY ./*.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false --no-restore

# App image
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Worker.dll"]
