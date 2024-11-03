const apiCall =
  'https://api.openweathermap.org/data/2.5/forecast?lat=43.528926&lon=-5.6556273&appid=a44d9a77f8c44c0eae4c88a4931c573f'
fetch(apiCall)
  .then((res) => {
    return res.json()
  })
  .then((data) => {
    console.log(JSON.stringify(data))
  })
