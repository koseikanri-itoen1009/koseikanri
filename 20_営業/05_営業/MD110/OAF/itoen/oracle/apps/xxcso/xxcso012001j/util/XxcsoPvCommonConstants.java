/*============================================================================
* ファイル名 : XxcsoPvCommonConstants
* 概要説明   : 物件汎用検索／パーソナライズビュー共通固定値クラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
* 2009-04-24 1.1  SCS柳平直人  [ST障害T1_634]作業依頼中フラグ追加対応
* 2009-12-24 1.2  SCS阿部大輔  [E_本稼動_00533]作業依頼中購買依頼No/顧客CD追加対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.util;

/*******************************************************************************
 * 物件汎用検索／パーソナライズビュー共通固定値クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvCommonConstants 
{
  /*****************************************************************************
   * URLパラメータ
   *****************************************************************************
   */
  public static final String EXECUTE_MODE_QUERY    = "QUERY";
  public static final String EXECUTE_MODE_CREATE   = "CREATE";
  public static final String EXECUTE_MODE_COPY     = "COPY";
  public static final String EXECUTE_MODE_UPDATE   = "UPDATE";

  public static final String PV_DISPLAY_MODE_1     = "1";
  public static final String PV_DISPLAY_MODE_2     = "2";

  /*****************************************************************************
   * プロファイルオプション値
   *****************************************************************************
   */
  public static final String XXCSO1_IB_PV_D_VIEW_LINES
                                                  = "XXCSO1_IB_PV_D_VIEW_LINES";

  /*****************************************************************************
   * アドバンステーブルリージョン名
   *****************************************************************************
   */
  public static final String EXTRACT_CONDITION_ADV_TBL_RN
                                                  = "ExtractConditionAdvTblRN";

  public static final String SELECT_VIEW_ADV_TBL_RN = "SelectViewAdvTblRN";

  /*****************************************************************************
   * 画面内固定値(パーソナライズビュー作成画面)
   *****************************************************************************
   */

  // パーソナライズビュー表示画面
  public static final int    VIEW_ID_SEED             = -1;
  public static final String DEFAULT_FLAG_YES         = "Y";
  public static final String DEFAULT_FLAG_NO          = "N";
  public static final String KEY_VIEW_ID              = "VIEW_ID";
  public static final String KEY_VIEW_NAME            = "VIEW_NAME";
  public static final String KEY_EXEC_MODE            = "EXEC_MODE";


  /*****************************************************************************
   * 画面内固定値(パーソナライズビュー作成画面)
   *****************************************************************************
   */

  public static final int    SORT_SETTING_SIZE        = 3;
  public static final String SORT_LINE_CAPTION1       = "第";
  public static final String SORT_LINE_CAPTION2       = "ソート";
  public static final String ADD_VIEW_NAME_COPY       = "の複製";

// 2009/04/24 [ST障害T1_634] Mod Start
//  public static final int    EXTRACT_SIZE             = 78;
// 2009/12/24 [E_本稼動_00533] Mod Start
//  public static final int    EXTRACT_SIZE             = 79;
  public static final int    EXTRACT_SIZE             = 80;
// 2009/12/24 [E_本稼動_00533] Mod End
// 2009/04/24 [ST障害T1_634] Mod End
  public static final String EXTRACT_RENDER           = "ExtractRender";
  public static final String EXTRACT_AND              = "1";
  public static final String EXTRACT_OR               = "2";

  public static final String EXTRACT_VALUE_010        = "010";
  public static final String EXTRACT_VALUE_030        = "030";
  public static final String EXTRACT_VALUE_090        = "090";

  public static final String EXTRACT_TYPE_VARCHAR2    = "VARCHAR2";
  public static final String EXTRACT_TYPE_NUMBER      = "NUMBER";
  public static final String EXTRACT_TYPE_DATE        = "DATE";
  
  public static final String VIEW_OPEN_CODE_OPEN      = "1";
  public static final String VIEW_OPEN_CODE_CLOSE     = "0";

  /*****************************************************************************
   * 画面内固定値 (物件情報汎用検索画面)
   *****************************************************************************
   */
  public static final String FLAG_ENABLE              = "1";

  public static final String EXTRACT_FIRST            = "1 = 1";

  public static final String COMMA                    = ",";
  public static final String SPACE                    = " ";
  public static final String SINGLE_QUOTE             = "'";

  public static final String METHOD_CONTAIN           = "3";
  public static final String METHOD_START             = "4";
  public static final String METHOD_END               = "5";

  public static final String REPLACE_WORD             = ":\\$V1";

  public static final String KEY_ID                   = "ID";
  public static final String KEY_NAME                 = "NAME";
  public static final String KEY_ATTR_NAME            = "ATTR_NAME";
  public static final String KEY_DATA_TYPE            = "DATA_TYPE";

  public static final String VIEW_NAME                = "InstallBasePvSumVO";

  public static final String RN_TABLE_LAYOUT_CELL0301 = "PvDesignCfRN0301";
  // 物件汎用情報Tableの固定値
  public static final String RN_TABLE                 = "InstallBaseTblRN";

  public static final String TABLE_WIDTH              = "100%";

  // 詳細imageの固定値
  public static final String IMAGE_LABEL              = "詳細の表示"; 
  public static final String IMAGE_SOURCE
                                 = "/OA_MEDIA/eyeglasses_24x24_transparent.gif"; 
  public static final String IMAGE_SHORT_DESC         = "詳細の表示"; 
  public static final String IMAGE_VIEW_ATTR          = "InstanceId"; 
  public static final String IMAGE_ACTION_NAME        = "DetailIconClick"; 
  public static final String IMAGE_FIRE_ACTION_NAME   = "SelectedInstanceId"; 
  public static final String IMAGE_FIRE_ACTION_PARAM  = "{$InstanceId}"; 
  public static final String IMAGE_HEIGHT             = "25"; 
  public static final String IMAGE_WIDTH              = "25"; 

  /*****************************************************************************
   * Switcher名
   *****************************************************************************
   */
  public static final String UPDATE_ENABLED           = "UpdateEnabled";
  public static final String UPDATE_DISABLED          = "UpdateDisabled";
  public static final String DELETE_ENABLED           = "DeleteEnabled";
  public static final String DELETE_DISABLED          = "DeleteDisabled";
  public static final String DEFAULT_FLAG             = "DefaultFlag";

  /*****************************************************************************
   * メッセージ用TOKEN
   *****************************************************************************
   */
  // パーソナライズビュー表示画面
  public static final String MSG_RECORD              = "レコード";
  public static final String MSG_VIEW                = "ビュー";
  public static final String MSG_VIEW_NAME           = "ビュー名";

  // パーソナライズビュー作成画面
  public static final String MSG_EXTRACT_COLUMN      = "検索条件";
  public static final String MSG_EXTRACT_TOKEN_010   = "拠点コード";
  public static final String MSG_EXTRACT_TOKEN_030   = "物件コード";
  public static final String MSG_EXTRACT_TOKEN_090   = "顧客コード";

}