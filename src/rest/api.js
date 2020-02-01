const express = require('express')
const app = express()

const startServer = () => {
  console.log('hoge');
  app.get('/api/getTodos', (req, res) => {
    // TODO
    res.send('todos')
  })

  app.listen(8000)
}

module.exports.startServer = startServer
