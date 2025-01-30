# Build Stage
FROM --platform=linux mcr.microsoft.com/dotnet/sdk:7.0 AS build
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM"

WORKDIR /source
COPY ./*.csproj ./
RUN dotnet restore

COPY . .  
RUN dotnet publish -c release -o /app --self-contained false --no-restore

# Runtime Stage
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Worker.dll"]
