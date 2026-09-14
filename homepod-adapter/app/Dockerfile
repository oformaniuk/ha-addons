FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS build
WORKDIR /src
COPY . .
RUN dotnet restore "HomeAssistantCompanion/HomeAssistantCompanion.csproj"
WORKDIR "/src/HomeAssistantCompanion"
RUN dotnet build "HomeAssistantCompanion.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "HomeAssistantCompanion.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "HomeAssistantCompanion.dll"]
