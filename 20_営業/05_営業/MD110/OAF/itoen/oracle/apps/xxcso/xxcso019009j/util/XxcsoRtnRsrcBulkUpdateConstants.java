/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateConstants
* 概要説明   : ルートNo/担当営業員一括更新画面共通固定値クラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基  新規作成
* 2009-03-05 1.1  SCS柳平直人  [CT1-034]重複営業員エラー対応
* 2010-03-23 1.2  SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.util;

/*******************************************************************************
 * アドオン：ルートNo/担当営業員一括更新画面の固定値クラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateConstants 
{
  public static final String MODE_FIRE_ACTION        = "FireAction";

  public static final String[] CENTERING_OBJECTS =
  {
// 2010-03-23 [E_本稼動_01942] Add Start
    "BaseCodeLayout",
// 2010-03-23 [E_本稼動_01942] Add End
    "ResourceLayout"
  };
  
  public static final String TOKEN_VALUE_PROCESS = "ルートNo／営業員一括更新";

// 2010-03-23 [E_本稼動_01942] Add Start
  public static final String TOKEN_VALUE_BASECODE       = "拠点ＣＤ";
// 2010-03-23 [E_本稼動_01942] Add End
  public static final String TOKEN_VALUE_EMPLOYEENUMBER = "営業員コード";
  public static final String TOKEN_VALUE_ROUTENO        = "ルートNo";
  public static final String TOKEN_VALUE_REFLECTMETHOD  = "反映方法";
  public static final String TOKEN_VALUE_ACCOUNTNUMBER  = "顧客コード";
  public static final String TOKEN_VALUE_PARTYNAME      = "顧客名";
  public static final String TOKEN_VALUE_TRGTRESOURCE   = "現担当";
  public static final String TOKEN_VALUE_TRGTROUTENO    = "現ルートNo";
  public static final String TOKEN_VALUE_NEXTRESOURCE   = "新担当";
  public static final String TOKEN_VALUE_NEXTROUTENO    = "新ルートNo";
  public static final String TOKEN_VALUE_ACCOUNT_INFO   = "顧客情報";

  public static final String MAPKEY_ACCOUNTNUMBER       = "ACCOUNTNUMBER";
  public static final String MAPKEY_PARTYNAME           = "PARTYNAME";

  public static final String BOOL_ISRSV                 = "Y";
  public static final String BOOL_ISNOTRSV              = "N";

  public static final String REFLECT_TRGT               = "1";
  public static final String REFLECT_RSV                = "2";
}