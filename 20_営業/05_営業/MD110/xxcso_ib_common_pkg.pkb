CREATE OR REPLACE PACKAGE BODY xxcso_ib_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IB_COMMON_PKG(BODY)
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
 *  2009/01/29    1.2   kyo              物件マスタ追加属性値情報取得関数２の修正
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_ib_common_pkg';   -- パッケージ名
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs
   * Description      : 物件マスタ追加属性値取得関数
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    lv_attribute_value        VARCHAR2(240);
--
  BEGIN
--
    -- システム日付取得（時分秒は切り捨て）
    ld_date := TRUNC(SYSDATE);
--
    -- プロファイル取得（XXCSO:IB拡張属性テンプレートアクセスレベル）
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- 属性値取得
    BEGIN
--
      SELECT
          civ.attribute_value  attribute_value
      INTO
          lv_attribute_value
      FROM
          csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
        , csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND civ.instance_id      = in_instance_id
      AND ciea.attribute_id    = civ.attribute_id
      AND NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN lv_attribute_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  固定部 END   ##########################################
  END get_ib_ext_attribs;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs2
   * Description      : 物件マスタ追加属性値取得関数２
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs2(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs2';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    lv_attribute_value        VARCHAR2(240);
--
  BEGIN
--
    -- 業務処理日付取得（時分秒は切り捨て）
    ld_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ld_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- プロファイル取得（XXCSO:IB拡張属性テンプレートアクセスレベル）
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- 属性値取得
    BEGIN
--
      SELECT
          civ.attribute_value  attribute_value
      INTO
          lv_attribute_value
      FROM
          csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
        , csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND civ.instance_id      = in_instance_id
      AND ciea.attribute_id    = civ.attribute_id
      AND NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN lv_attribute_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  固定部 END   ##########################################
  END get_ib_ext_attribs2;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs_id
   * Description      : 物件マスタ追加属性ID取得関数
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs_id(
    iv_attribute_code    IN  VARCHAR2,  -- 属性コード
    id_standard_date     IN  DATE       -- 基準日
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs_id';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_attribute_id           NUMBER;
    ld_standard_date          DATE;
    lv_attribute_level        VARCHAR2(15);
--
  BEGIN
--
    -- 基準日取得（時分秒は切り捨て）
    ld_standard_date := TRUNC( id_standard_date );
--
    IF ld_standard_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- プロファイル取得（XXCSO:IB拡張属性テンプレートアクセスレベル）
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    BEGIN
      SELECT
          ciea.attribute_id  attribute_id
      INTO
          ln_attribute_id
      FROM
          csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND NVL( ciea.active_start_date, ld_standard_date ) <= ld_standard_date
      AND NVL( ciea.active_end_date, ld_standard_date )   >= ld_standard_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN ln_attribute_id;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  固定部 END   ##########################################
  END get_ib_ext_attribs_id;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attrib_info2
   * Description      : 物件マスタ追加属性値取得関数２
   ***********************************************************************************/
  FUNCTION get_ib_ext_attrib_info2(
    in_instance_id       IN  NUMBER,   -- インスタンスID
    iv_attribute_code    IN  VARCHAR2  -- 属性定義
  )
  RETURN CSI_IEA_VALUES%ROWTYPE
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attrib_info2';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    l_ext_attrib_rec          csi_iea_values%ROWTYPE;
--
  BEGIN
--
    -- 業務処理日付取得（時分秒は切り捨て）
    ld_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ld_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- プロファイル取得（XXCSO:IB拡張属性テンプレートアクセスレベル）
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- 属性値情報取得
    BEGIN
--
      SELECT civ.attribute_value_id     attribute_value_id
           , civ.attribute_value        attribute_value
           , civ.object_version_number  object_version_number
           , civ.attribute_id           attribute_id
      INTO   l_ext_attrib_rec.attribute_value_id
           , l_ext_attrib_rec.attribute_value
           , l_ext_attrib_rec.object_version_number
           , l_ext_attrib_rec.attribute_id
      FROM   csi_i_extended_attribs  ciea  -- 設置機器拡張属性定義情報テーブル
           , csi_iea_values          civ   -- 設置機器拡張属性値情報テーブル
      WHERE  ciea.attribute_level = lv_attribute_level
      AND    ciea.attribute_code  = iv_attribute_code
      AND    civ.instance_id      = in_instance_id
      AND    ciea.attribute_id    = civ.attribute_id
      AND    NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND    NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN l_ext_attrib_rec;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  固定部 END   ##########################################
  END get_ib_ext_attrib_info2;
--
END xxcso_ib_common_pkg;
/
