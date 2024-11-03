#!/usr/bin/env node

const WEATHER_ICON = {
  '01d': ' ',
  '01n': ' ',
  '02d': '  ',
  '02n': '  ',
  '03d': '  ',
  '03n': '  ',
  '04d': '  ',
  '04n': '  ',
  '09d': '  ',
  '09n': '  ',
  '10d': '  ',
  '10n': '  ',
  '11d': '  ',
  '11n': '  ',
  '13d': '  ',
  '13n': '  ',
  '50d': '  ',
  '50n': '  ',
}

const apiKey = 'a44d9a77f8c44c0eae4c88a4931c573f'
const lat = '43.528926'
const lon = '-5.6556273'
const apiCall = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`

async function getWeather(apiCall, WEATHER_ICON) {
  const response = await fetch(apiCall).then((res) => res.json())
  const iconCode = response.weather[0].icon
  const icon = getIcon(iconCode, WEATHER_ICON)
  const forecast = {
    currentWeather: response.weather[0].main,
    currentWeatherDescription: response.weather[0].description,
    currentWeatherIcon: icon,
    currentTemperature: response.main.temp,
    currentThemalSensation: response.main.feels_like,
    currentMinTemperature: response.main.temp_min,
    currentMaxTemperature: response.main.temp_max,
    currentHumidity: response.main.humidity + ' %',
    currentCity: response.name,
  }
  console.log(JSON.stringify(forecast))
  return forecast
}

function getIcon(code, objectWeather) {
  return objectWeather[code]
}

getWeather(apiCall, WEATHER_ICON)
