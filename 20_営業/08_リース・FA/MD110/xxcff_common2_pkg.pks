CREATE OR REPLACE PACKAGE XXCFF_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON2_PKG(spec)
 * Description      : FAリース共通処理
 * MD.050           : なし
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_match_chk      支払照合済チェック
 *  get_lease_key          リースキーの取得
 *  get_object_info        物件コードリース区分、リース種別チェック
 *  chk_object_term        物件コード解約チェック
 *  get_lease_class_info   リース種別DFF情報取得
 *  <program name>         <説明> (処理番号)
 *  作成順に記述していくこと
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0    SCS大井          新規作成
 *  2008/12/05    1.1    SCS嶋田          追加：物件コード解約チェック
 *  2018/03/27    1.2    SCSK大塚         追加：リース種別DFF情報取得
 *
 *****************************************************************************************/
--
  --支払照合済チェック
 PROCEDURE payment_match_chk(
    in_line_id    IN  NUMBER,          -- 1.契約内部ID
    ov_errbuf     OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ   --# 固定 #
  );
  --リースキーの取得
  PROCEDURE get_lease_key(
    iv_objectcode IN  VARCHAR2,        --   1.物件コード(必須)
    on_object_id  OUT NUMBER,          --   2.物件内部ＩＤ
    on_contact_id OUT NUMBER,          --   3.契約内部ＩＤ
    on_line_id    OUT NUMBER,          --   4.契約明細内部ＩＤ
    ov_errbuf     OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ   --# 固定 #
  );
  --物件コードリース区分、リース種別チェック
  PROCEDURE get_object_info(
    in_object_id   IN  NUMBER,          --   1.物件コード(必須)
    iv_lease_type  IN  VARCHAR2,        --   2.リース区分(必須)
    iv_lease_class IN  VARCHAR2,        --   3.リース種別(必須)
    in_re_lease_times IN  NUMBER,       --   4.再リース回数（必須）
    ov_errbuf      OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ   --# 固定 #
  );
  --物件コード解約チェック
  PROCEDURE chk_object_term(
    in_object_header_id  IN  NUMBER,               --   1.物件内部ID(必須)
    iv_term_appl_chk_flg IN  VARCHAR2 DEFAULT 'N', --   2.解約申請チェックフラグ(デフォルト値：'N')
    ov_errbuf            OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2       --   ユーザー・エラー・メッセージ --# 固定 #
  );
  -- リース種別DFF情報取得
  PROCEDURE get_lease_class_info(
    iv_lease_class  IN VARCHAR2,          -- 1.リース種別
    ov_ret_dff4     OUT VARCHAR2,         -- DFF4のデータ格納用
    ov_ret_dff5     OUT VARCHAR2,         -- DFF5のデータ格納用
    ov_ret_dff6     OUT VARCHAR2,         -- DFF6のデータ格納用
    ov_ret_dff7     OUT VARCHAR2,         -- DFF7のデータ格納用
    ov_errbuf       OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
  );
END XXCFF_COMMON2_PKG;
/
