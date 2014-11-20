CREATE OR REPLACE PACKAGE XXCFF_COMMON1_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON1_PKG(spec)
 * Description      : リース・FA領域共通関数１
 * MD.050           : なし
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  init                         P    -     初期処理
 *  put_log_param                P    -     コンカレントパラメータ出力処理
 *  chk_fa_location              P    -     事業所マスタチェック
 *  chk_fa_category              P    -     資産カテゴリチェック
 *  chk_life                     P    -     耐用年数チェック
 *  作成順に記述していくこと
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS山岸謙一      新規作成
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE init_rtype IS RECORD (
     process_date              DATE         -- 業務日付
    ,set_of_books_id           NUMBER(15)   -- 会計帳簿ID
    ,currency_code             VARCHAR2(15) -- 機能通貨
    ,org_id                    NUMBER(15)   -- 営業単位
    ,gl_application_short_name VARCHAR2(50) -- GLアプリケーション短縮名
    ,chart_of_accounts_id      NUMBER(15)   -- 科目体系番号ID
    ,id_flex_code              VARCHAR2(4)  -- キーフレックスコード
   );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- ===============================
  -- ユーザー定義共通関数
  -- ===============================
  -- 初期処理
  PROCEDURE init(
    or_init_rec   OUT NOCOPY init_rtype,   --   戻り値
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- コンカレントパラメータ出力処理
  PROCEDURE put_log_param(
    iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT',  -- 出力区分
    ov_errbuf   OUT NOCOPY VARCHAR2,            --エラーメッセージ
    ov_retcode  OUT NOCOPY VARCHAR2,            --リターンコード
    ov_errmsg   OUT NOCOPY VARCHAR2             --ユーザー・エラーメッセージ
  );
--
  -- 事業所マスタチェック
  PROCEDURE chk_fa_location(
    iv_segment1    IN  VARCHAR2 DEFAULT NULL, -- 申告地
    iv_segment2    IN  VARCHAR2,              -- 管理部門
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- 事業所
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- 場所
    iv_segment5    IN  VARCHAR2,              -- 本社／工場
    on_location_id OUT NOCOPY NUMBER,         -- 事業所ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 資産カテゴリチェック
  PROCEDURE chk_fa_category(
    iv_segment1    IN  VARCHAR2,              -- 種類
    iv_segment2    IN  VARCHAR2 DEFAULT NULL, -- 申告償却
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- 資産勘定
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- 償却科目
    iv_segment5    IN  VARCHAR2,              -- 耐用年数
    iv_segment6    IN  VARCHAR2 DEFAULT NULL, -- 償却方法
    iv_segment7    IN  VARCHAR2,              -- リース種別
    on_category_id OUT NOCOPY NUMBER,         -- 資産カテゴリID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 耐用年数チェック
  PROCEDURE chk_life(
    iv_category    IN  VARCHAR2,           --   資産種類
    iv_life        IN  VARCHAR2,           --   耐用年数
    ov_errbuf      OUT NOCOPY VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  );

END XXCFF_COMMON1_PKG;
/
