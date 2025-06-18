module ErrorsHelper
  def error_title(code)
    case code
    when 404 then "ページが見つかりませんでした... 🥺💦"
    when 422 then "リクエストが処理できませんでした… 😢"
    when 500 then "予期しないエラーが発生しました 😵‍💫"
    else           "予期せぬエラーが発生しました…😵"
    end
  end

  def error_desc(code)
    case code
    when 404 then "ページが削除された可能性があります 🤔💭"
    when 422 then "入力内容に誤りがあるか、リクエストが正しく送信されなかった可能性があります。"
    when 500 then "申し訳ありません。サーバーで問題が発生しています。"
    else           "ご迷惑をおかけして、大変申し訳ありません。"
    end
  end
end
