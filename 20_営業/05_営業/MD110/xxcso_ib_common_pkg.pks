CREATE OR REPLACE PACKAGE xxcso_ib_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IB_COMMON_PKG(SPEC)
 * Description      : 共通関数（XXCSOIB共通）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  get_ib_ext_attribs     F     V     物件マスタ追加属性値取得関数
 *  get_ib_ext_attribs2    F     V     物件マスタ追加属性値取得関数２
 *  get_ib_ext_attribs_id  F     V     物件マスタ追加属性ID取得関数
 *  get_ib_ext_attrib_info2 F    R     物件マスタ追加属性値情報取得関数２
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   N.Yabuki         新規作成
 *  2009/01/16    1.1   N.Yabuki         物件マスタ追加属性値情報取得関数２を追加
 *
 *****************************************************************************************/
--
  -- 物件マスタ追加属性値取得関数
  FUNCTION get_ib_ext_attribs(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN VARCHAR2;
--
  -- 物件マスタ追加属性値取得関数２
  FUNCTION get_ib_ext_attribs2(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN VARCHAR2;
--
  -- 物件マスタ追加属性ID取得関数
  FUNCTION get_ib_ext_attribs_id(
    iv_attribute_code    IN  VARCHAR2,  -- 属性コード
    id_standard_date     IN  DATE       -- 基準日
  )
  RETURN NUMBER;
--
  -- 物件マスタ追加属性値情報取得関数２
  FUNCTION get_ib_ext_attrib_info2(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN CSI_IEA_VALUES%ROWTYPE;
--
END xxcso_ib_common_pkg;
/
