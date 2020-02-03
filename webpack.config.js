const path = require("path");
const webpack = require("webpack");

const { startServer } = require('./src/rest/api.js')

const { getTodos } = require('./src/repository/TodoRepository.js')

const bodyParser = require('body-parser')

const HTMLWebpackPlugin = require("html-webpack-plugin");

module.exports = {
    mode: 'development',
    entry: "./src/index.js",
    output: {
        path: path.join(__dirname, "dist"),
        filename: 'bundle.js'
    },
    plugins: [
        new HTMLWebpackPlugin({
            template: "./template/index.html",
            inject: "body"
        }),
        new webpack.NamedModulesPlugin(),
        new webpack.NoEmitOnErrorsPlugin()
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".elm"]
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader"
                }
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    { loader: "elm-hot-webpack-loader" },
                    {
                      loader: "elm-webpack-loader",
                      options: {
                          debug: true,
                          forceWatch: true
                      }
                    }
                ]
            }
        ]
    },
    devServer: {
        inline: true,
        stats: "errors-only",
        host: '0.0.0.0',
        disableHostCheck: true,
        historyApiFallback: true,
        before(app) {
          app.use(bodyParser.urlencoded({ extended : true }))
          app.use(bodyParser.json())
          app.get('/api/v1/todo', async (req, res) => {
            const { id } = req.query
            const todos = await getTodos({ id })
            res.json({
              result : todos
            })
          })
        }
    }
};
