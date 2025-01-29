const WEATHER_ICON = {
  "01d": " ",
  "01n": " ",
  "02d": "  ",
  "02n": "  ",
  "03d": "  ",
  "03n": "  ",
  "04d": "  ",
  "04n": "  ",
  "09d": "  ",
  "09n": "  ",
  "10d": "  ",
  "10n": "  ",
  "11d": "  ",
  "11n": "  ",
  "13d": "  ",
  "13n": "  ",
  "50d": "  ",
  "50n": "  ",
};
type Weather = {
  coord: Coord;
  weather: WeatherElement[];
  base: string;
  main: Main;
  visibility: number;
  wind: Wind;
  clouds: Clouds;
  dt: number;
  sys: Sys;
  timezone: number;
  id: number;
  name: string;
  cod: number;
};

type Clouds = {
  all: number;
};

type Coord = {
  lon: number;
  lat: number;
};

type Main = {
  temp: number;
  feels_like: number;
  temp_min: number;
  temp_max: number;
  pressure: number;
  humidity: number;
};

type Sys = {
  type: number;
  id: number;
  country: string;
  sunrise: number;
  sunset: number;
};

type WeatherElement = {
  id: number;
  main: string;
  description: string;
  icon: string;
};

type Wind = {
  speed: number;
  deg: number;
  gust: number;
};

const apiKey = process.env.API_WEATHER;
const lat = "43.528926";
const lon = "-5.6556273";

async function get_weather(retries = 0) {
  let local_retries = retries;
  if (local_retries > 5) {
    console.log(
      JSON.stringify({
        text: " 😭 ",
        data: " 😭 ",
      }),
    );
    return;
  }
  try {
    const response: Weather = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`,
    ).then((res) => res.json());
    let description = response.weather[0].description;
    description = description.charAt(0).toUpperCase() + description.slice(1);
    const data = {
      text: `${WEATHER_ICON[response.weather[0].icon]}  ${Math.ceil(
        response.main.temp,
      )}°`,
      tooltip: `<b> ${
        WEATHER_ICON[response.weather[0].icon]
      } ${description} </b> \n Feels like ${Math.ceil(
        response.main.feels_like,
      )}° in ${response.name}`,
    };
    console.log(JSON.stringify(data));
    local_retries = 0;
  } catch (error) {
    setTimeout(() => {
      local_retries = local_retries + 1;
      get_weather(local_retries);
    }, 1000 * 60);
  }
}

get_weather();
