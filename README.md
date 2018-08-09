AFI Checker
=====

各ASPの成果を一覧できる

## Description

スクレイピングで各ASPの発生額などを取得し、CSVダウンロードできる。

## Install＆Usage

1. `security.yml`にログイン用のIDとパスワードを入力

ex)
```yml
a8:
  id: example
  password: abcdefghijk

...
```

2. 下記をターミナルで実行してください。

```
$ bundle install
$ bundle exec ruby main.rb
```

3. `data.csv`としてダウンロードされます
