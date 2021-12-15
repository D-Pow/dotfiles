I finally solved the issue! There were a couple of things I needed to do to make this work, some of which were admittedly project-specific, but I still think important to point out so others don’t have this issue.

1. We had a `new ExtractTextPlugin('./src/styles/index.scss')` declaration in our `config.plugins` array. This made the final build reference an SCSS file instead of CSS, so I simply removed the “s”
2. Since the confluence installation documentation said we needed to import design-language via `import 'design-language/dist/design-language.css';` and our project was previously setup to use CSS modules, I needed to be able to accept both. So, to both sass and css entries in the `config.modules.rules` array, anywhere `css-loader.options.modules === true`, I also added `import: false`
3. The biggest change I needed to make was to add a new rule to parse the design-language.css files. I placed the new rule before the CSS rule, but only because I think order matters in the `rules` array. The new rule was to use `ExtractTextPlugin` because for some reason the css-loader wouldn’t work. The rule was

```javascript
{
    test: /design-language.*\.s?css$/,
    use: ExtractTextPlugin.extract({
        fallback: 'style-loader',
        use: ['css-loader']
    })
},
```

which I got from [here](https://hackernoon.com/a-tale-of-webpack-4-and-how-to-finally-configure-it-in-the-right-way-4e94c8e7e5c1#1a7b). Since the design-language.css should be processed by the above rule, remove it from the standard CSS rule: after the `use` array, I added `include: [path.resolve(__dirname, 'src')]` so that our CSS rule only parsed the src/ folder and not the node_modules folder.
4. Finally, since design-language uses a bunch of fonts and other files, I needed to add/update our SVG rule to accept all those other files, too:
```// Process fonts and other files
    {
        test: /\.(otf|woff2?|eot|ttf|svg)$/,
        exclude: [/\.(s?css|jsx?|html)$/],
        use: {
            loader: 'file-loader',
            options: {
                outputPath: 'fonts',
                publicPath: '../fonts'
            }
        }
    }
}```
