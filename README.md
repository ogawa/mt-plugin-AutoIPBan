# AutoIPBanプラグイン

IPBanListデータベースのユーティリティ機能を実現するプラグイン。具体的には、トラックバックスロットリングの対象となったIPアドレスを自動的にIPBanListに追加する機能、コメント･トラックバック一覧から一括して送信元IPアドレスをIPBanListに追加する機能、IPBanListの情報をテンプレートから利用する機能を実現します。

## 更新履歴

 * 0.01(2006-05-12)
   * 公開。
 * 0.02(2006-05-14)
   * コメントまたはトラックバックの一覧画面で、選択したコメントまたはトラックバックの送信元IPアドレスをまとめてIPBanListに追加する機能を追加しました。
   * テンプレートからIPBanListにアクセスできるようにしました。この機能を用いることで.htaccessのdeny hostリストをMovable Typeを使って生成することができます。

## 概要

Movable Type 3.2には以下の複数のトラックバックスパム防止機能が標準的に組み込まれています。

 1. IPBanListによるIPアドレスに基づいたトラックバック禁止機能
 1. トラックバックのスロットリング機能(OneHourMaxPings, OneDayMaxPings)
 1. SpamLookupによるJunk Folderへの振り分け機能

これらの機能はこの順で適用されますから、3.よりは2.、2.よりは1.の機能を用いてより多くのトラックバックスパムを防止できれば、それだけサーバ負荷の削減に繋がります。

AutoIPBan Pluginは、このIPBanListデータを簡便に追加・参照するための以下の機能を提供します。

 * トラックバックスロットリングの対象となったIPアドレスを自動追加機能
 * コメント・トラックバックの送信元IPアドレスを一括追加機能
 * IPBanListを参照するテンプレートタグ機能

詳しくは使い方を参照のこと。

## インストール方法

AutoIPBan.plをMovable Typeのpluginsディレクトリにコピーするだけです。

## 使い方

まず、MT 3.2では、デフォルトでIPBanListがMT CMSから直接閲覧できないようになっています。mt-config.cgiに以下の行を加えると、各ブログの設定画面に「禁止IPアドレス」というリンクが表示されるようになります。

    ShowIPInformation 1

AutoIPBan Pluginはこの「禁止IPアドレス」データを簡便に操作するいくつかの機能を提供します。以下では、個々の機能とその利用方法を述べます。

### トラックバックスロットリングの対象となったIPアドレスの自動追加

トラックバックスロットリングの対象となったIPアドレスは自動的にIPBanListに追加されます。これにより、次回からそのIPアドレスからのトラックバックを禁止します。

この機能は、AutoIPBan Pluginをインストールするだけで有効になります。トラックバックスロットリング用のパラメータOneHourMaxPings, OneDayMaxPingsはmt-config.cgiの中で適宜設定できます。

### コメント・トラックバックの送信元IPアドレスの一括追加

コメント・トラックバックの一覧画面から選択したアイテムの送信元IPアドレスをIPBanListに追加できます。

任意個のアイテムを選択して、右上のアイテムアクションメニューから「Add To IPBanList」を選択して、「Go」をクリックするだけです。IPアドレスがすでにIPBanListに含まれている場合には重複して追加されないようになっています。

### IPBanListを参照するテンプレートタグ

IPBanListの情報にアクセスする、MTIPBanListコンテナタグ、MTIPBanListIPタグがテンプレート内で使用できます。以下の例ではIPBanListのIPアドレスをリストアップします。

    <ul>
      <MTIPBanList>
        <li><$MTIPBanListIP$></li>
      </MTIPBanList>
    </ul>

MTIPBanListコンテナタグには以下のオプションを指定できます。

 * blog_id: 対象となるブログのIDを指定します。MTIPBanListはデフォルトでカレントブログのIPBanListをリストしますが、カレントブログ以外のブログのIPBanListをリストしたいときに指定します。IDはカンマで区切って複数指定することもできます。例えば、「blog_id="1,2,3"」と指定すると、IDが1,2,3のブログのIPBanListを参照することができます。
 * glue: リストアップ時にglueで指定された文字列をタグの間に挿入・表示します。

また、これらのタグを使って.htaccessのdeny hostリストをMovable Typeを使って生成することができます。

    Order allow,deny
    allow from all
    <MTIPBanList>
    deny from <$MTIPBanListIP$>
    </MTIPBanList>

## See Also

## License

This code is released under the Artistic License. The terms of the Artistic License are described at [http://www.perl.com/language/misc/Artistic.html](http://www.perl.com/language/misc/Artistic.html).

## Author & Copyright

Copyright 2006, Hirotaka Ogawa (hirotaka.ogawa at gmail.com)
