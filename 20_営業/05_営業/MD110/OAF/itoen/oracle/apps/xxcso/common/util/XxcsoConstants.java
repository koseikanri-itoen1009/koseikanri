/*============================================================================
* ファイル名 : XxcsoConstants
* 概要説明   : 【アドオン：営業・営業領域】共通固定値クラス
* バージョン : 1.21
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS小川浩    新規作成
* 2009-02-24 1.1  SCS柳平直人  [内部障害-030]メッセージ追加（APP-XXCSO1-00546）
* 2009-03-05 1.1  SCS柳平直人  [CT1-034]メッセージ追加（APP-XXCSO1-00555）
* 2009-04-08 1.2  SCS柳平直人  [ST障害T1_0364]メッセージ追加（APP-XXCSO1-00558）
*                                             メッセージ追加（APP-XXCSO1-00559）
* 2009-04-27 1.3  SCS柳平直人  [ST障害T1_0708]文字列チェック処理統一修正
* 2009-05-26 1.4  SCS柳平直人  [ST障害T1_1165]メッセージ追加（APP-XXCSO1-00571）
* 2009-06-08 1.5  SCS柳平直人  [ST障害T1_1307]メッセージ追加（APP-XXCSO1-00573）
* 2009-06-16 1.6  SCS阿部大輔  [ST障害T1_1257]メッセージ追加（APP-XXCSO1-00574）
* 2009-11-29 1.7  SCS阿部大輔  [E_本稼動_00106]アカウント複数対応
* 2010-01-12 1.8  SCS阿部大輔  [E_本稼動_00823]顧客マスタの整合性チェック対応
* 2010-01-20 1.9  SCS阿部大輔  [E_本稼動_01212]口座番号対応
* 2010-02-09 1.10 SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
* 2010-03-01 1.11 SCS阿部大輔  [E_本稼動_01678]現金支払対応
* 2010-03-01 1.11 SCS阿部大輔  [E_本稼動_01868]物件対応
* 2010-03-23 1.12 SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
* 2011-01-06 1.13 SCS桐生和幸  [E_本稼動_02498]銀行支店マスタチェック対応
* 2011-04-04 1.14 SCS吉元強樹  [E_本稼動_02496]SP専決回送先承認者必須チェック対応
* 2011-05-17 1.15 SCS桐生和幸  [E_本稼動_02500]原価割れチェック方法の変更対応
* 2011-06-06 1.16 SCS桐生和幸  [E_本稼動_01963]新規仕入先作成チェック対応
* 2011-11-14 1.17 SCSK桐生和幸 [E_本稼動_08312]問屋見積画面の改修①
* 2012-06-12 1.18 SCSK桐生和幸 [E_本稼動_09602]契約取消ボタン追加対応
* 2013-04-01 1.19 SCSK桐生和幸 [E_本稼動_10413]銀行口座マスタ変更チェック追加対応
* 2013-04-19 1.20 SCSK桐生和幸 [E_本稼動_09603]契約書未確定による顧客区分遷移の変更対応
* 2014-01-31 1.21 SCSK桐生和幸 [E_本稼動_11397]売価1円対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

/*******************************************************************************
 * アドオン：営業・営業領域の共通固定値クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoConstants 
{
  /*****************************************************************************
   * デバッグオプション（ローカル確認時のみtrueにすること）
   *****************************************************************************
   */
  public static final boolean DEBUG_OPTION       = false;
  
  /*****************************************************************************
   * メッセージ名
   *****************************************************************************
   */

  public static final String APP_XXCSO1_00001    = "APP-XXCSO1-00001";
  public static final String APP_XXCSO1_00002    = "APP-XXCSO1-00002";
  public static final String APP_XXCSO1_00003    = "APP-XXCSO1-00003";
  public static final String APP_XXCSO1_00004    = "APP-XXCSO1-00004";
  public static final String APP_XXCSO1_00005    = "APP-XXCSO1-00005";
  public static final String APP_XXCSO1_00006    = "APP-XXCSO1-00006";
  public static final String APP_XXCSO1_00007    = "APP-XXCSO1-00007";
  public static final String APP_XXCSO1_00008    = "APP-XXCSO1-00008";
  public static final String APP_XXCSO1_00009    = "APP-XXCSO1-00009";
  public static final String APP_XXCSO1_00010    = "APP-XXCSO1-00010";
  public static final String APP_XXCSO1_00014    = "APP-XXCSO1-00014";
  public static final String APP_XXCSO1_00037    = "APP-XXCSO1-00037";
  public static final String APP_XXCSO1_00039    = "APP-XXCSO1-00039";
  public static final String APP_XXCSO1_00040    = "APP-XXCSO1-00040";
  public static final String APP_XXCSO1_00041    = "APP-XXCSO1-00041";
  public static final String APP_XXCSO1_00042    = "APP-XXCSO1-00042";
  public static final String APP_XXCSO1_00044    = "APP-XXCSO1-00044";
  public static final String APP_XXCSO1_00046    = "APP-XXCSO1-00046";
  public static final String APP_XXCSO1_00047    = "APP-XXCSO1-00047";
  public static final String APP_XXCSO1_00074    = "APP-XXCSO1-00074";
  public static final String APP_XXCSO1_00115    = "APP-XXCSO1-00115";
  public static final String APP_XXCSO1_00120    = "APP-XXCSO1-00120";
  public static final String APP_XXCSO1_00121    = "APP-XXCSO1-00121";
  public static final String APP_XXCSO1_00125    = "APP-XXCSO1-00125";
  public static final String APP_XXCSO1_00133    = "APP-XXCSO1-00133";
  public static final String APP_XXCSO1_00126    = "APP-XXCSO1-00126";
  public static final String APP_XXCSO1_00223    = "APP-XXCSO1-00223";
  public static final String APP_XXCSO1_00229    = "APP-XXCSO1-00229";
  public static final String APP_XXCSO1_00232    = "APP-XXCSO1-00232";
  public static final String APP_XXCSO1_00236    = "APP-XXCSO1-00236";
  public static final String APP_XXCSO1_00248    = "APP-XXCSO1-00248";
  public static final String APP_XXCSO1_00249    = "APP-XXCSO1-00249";
  public static final String APP_XXCSO1_00273    = "APP-XXCSO1-00273";
  public static final String APP_XXCSO1_00286    = "APP-XXCSO1-00286";
  public static final String APP_XXCSO1_00287    = "APP-XXCSO1-00287";
  public static final String APP_XXCSO1_00288    = "APP-XXCSO1-00288";
  public static final String APP_XXCSO1_00289    = "APP-XXCSO1-00289";
  public static final String APP_XXCSO1_00290    = "APP-XXCSO1-00290";
  public static final String APP_XXCSO1_00291    = "APP-XXCSO1-00291";
  public static final String APP_XXCSO1_00292    = "APP-XXCSO1-00292";
  public static final String APP_XXCSO1_00293    = "APP-XXCSO1-00293";
  public static final String APP_XXCSO1_00294    = "APP-XXCSO1-00294";
  public static final String APP_XXCSO1_00295    = "APP-XXCSO1-00295";
  public static final String APP_XXCSO1_00298    = "APP-XXCSO1-00298";
  public static final String APP_XXCSO1_00299    = "APP-XXCSO1-00299";
  public static final String APP_XXCSO1_00300    = "APP-XXCSO1-00300";
  public static final String APP_XXCSO1_00301    = "APP-XXCSO1-00301";
  public static final String APP_XXCSO1_00303    = "APP-XXCSO1-00303";
  public static final String APP_XXCSO1_00304    = "APP-XXCSO1-00304";
  public static final String APP_XXCSO1_00306    = "APP-XXCSO1-00306";
  public static final String APP_XXCSO1_00310    = "APP-XXCSO1-00310";
  public static final String APP_XXCSO1_00311    = "APP-XXCSO1-00311";
  public static final String APP_XXCSO1_00312    = "APP-XXCSO1-00312";
  public static final String APP_XXCSO1_00313    = "APP-XXCSO1-00313";
  public static final String APP_XXCSO1_00314    = "APP-XXCSO1-00314";
  public static final String APP_XXCSO1_00315    = "APP-XXCSO1-00315";
  public static final String APP_XXCSO1_00316    = "APP-XXCSO1-00316";
  public static final String APP_XXCSO1_00320    = "APP-XXCSO1-00320";
  public static final String APP_XXCSO1_00335    = "APP-XXCSO1-00335";
  public static final String APP_XXCSO1_00336    = "APP-XXCSO1-00336";
// 2011-04-04 v1.14 T.Yoshimoto Add Start E_本稼動_02496
  public static final String APP_XXCSO1_00345    = "APP-XXCSO1-00345";
// 2011-04-04 v1.14 T.Yoshimoto Add End E_本稼動_02496  
  public static final String APP_XXCSO1_00396    = "APP-XXCSO1-00396";
  public static final String APP_XXCSO1_00397    = "APP-XXCSO1-00397";
  public static final String APP_XXCSO1_00398    = "APP-XXCSO1-00398";
  public static final String APP_XXCSO1_00403    = "APP-XXCSO1-00403";
  public static final String APP_XXCSO1_00404    = "APP-XXCSO1-00404";
  public static final String APP_XXCSO1_00405    = "APP-XXCSO1-00405";
  public static final String APP_XXCSO1_00406    = "APP-XXCSO1-00406";
  public static final String APP_XXCSO1_00407    = "APP-XXCSO1-00407";
  public static final String APP_XXCSO1_00408    = "APP-XXCSO1-00408";
  public static final String APP_XXCSO1_00409    = "APP-XXCSO1-00409";
  public static final String APP_XXCSO1_00410    = "APP-XXCSO1-00410";
  public static final String APP_XXCSO1_00422    = "APP-XXCSO1-00422";
  public static final String APP_XXCSO1_00423    = "APP-XXCSO1-00423";
  public static final String APP_XXCSO1_00424    = "APP-XXCSO1-00424";
  public static final String APP_XXCSO1_00425    = "APP-XXCSO1-00425";
  public static final String APP_XXCSO1_00426    = "APP-XXCSO1-00426";
  public static final String APP_XXCSO1_00448    = "APP-XXCSO1-00448";
  public static final String APP_XXCSO1_00449    = "APP-XXCSO1-00449";
  public static final String APP_XXCSO1_00450    = "APP-XXCSO1-00450";
  public static final String APP_XXCSO1_00451    = "APP-XXCSO1-00451";
  public static final String APP_XXCSO1_00452    = "APP-XXCSO1-00452";
  public static final String APP_XXCSO1_00453    = "APP-XXCSO1-00453";
  public static final String APP_XXCSO1_00454    = "APP-XXCSO1-00454";
  public static final String APP_XXCSO1_00455    = "APP-XXCSO1-00455";
  public static final String APP_XXCSO1_00460    = "APP-XXCSO1-00460";
  public static final String APP_XXCSO1_00461    = "APP-XXCSO1-00461";
  public static final String APP_XXCSO1_00462    = "APP-XXCSO1-00462";
  public static final String APP_XXCSO1_00463    = "APP-XXCSO1-00463";
  public static final String APP_XXCSO1_00464    = "APP-XXCSO1-00464";
  public static final String APP_XXCSO1_00466    = "APP-XXCSO1-00466";
  public static final String APP_XXCSO1_00467    = "APP-XXCSO1-00467";
  public static final String APP_XXCSO1_00474    = "APP-XXCSO1-00474";
  public static final String APP_XXCSO1_00475    = "APP-XXCSO1-00475";
  public static final String APP_XXCSO1_00479    = "APP-XXCSO1-00479";
  public static final String APP_XXCSO1_00480    = "APP-XXCSO1-00480";
  public static final String APP_XXCSO1_00481    = "APP-XXCSO1-00481";
  public static final String APP_XXCSO1_00482    = "APP-XXCSO1-00482";
  public static final String APP_XXCSO1_00483    = "APP-XXCSO1-00483";
  public static final String APP_XXCSO1_00484    = "APP-XXCSO1-00484";
  public static final String APP_XXCSO1_00485    = "APP-XXCSO1-00485";
  public static final String APP_XXCSO1_00486    = "APP-XXCSO1-00486";
  public static final String APP_XXCSO1_00487    = "APP-XXCSO1-00487";
  public static final String APP_XXCSO1_00488    = "APP-XXCSO1-00488";
  public static final String APP_XXCSO1_00489    = "APP-XXCSO1-00489";
  public static final String APP_XXCSO1_00490    = "APP-XXCSO1-00490";
  public static final String APP_XXCSO1_00491    = "APP-XXCSO1-00491";
  public static final String APP_XXCSO1_00494    = "APP-XXCSO1-00494";
  public static final String APP_XXCSO1_00498    = "APP-XXCSO1-00498";
  public static final String APP_XXCSO1_00499    = "APP-XXCSO1-00499";
  public static final String APP_XXCSO1_00514    = "APP-XXCSO1-00514";
  public static final String APP_XXCSO1_00515    = "APP-XXCSO1-00515";
  public static final String APP_XXCSO1_00520    = "APP-XXCSO1-00520";
  public static final String APP_XXCSO1_00521    = "APP-XXCSO1-00521";
  public static final String APP_XXCSO1_00522    = "APP-XXCSO1-00522";
  public static final String APP_XXCSO1_00523    = "APP-XXCSO1-00523";
  public static final String APP_XXCSO1_00526    = "APP-XXCSO1-00526";
  public static final String APP_XXCSO1_00527    = "APP-XXCSO1-00527";
  public static final String APP_XXCSO1_00528    = "APP-XXCSO1-00528";
  public static final String APP_XXCSO1_00529    = "APP-XXCSO1-00529";
  public static final String APP_XXCSO1_00530    = "APP-XXCSO1-00530";
  public static final String APP_XXCSO1_00532    = "APP-XXCSO1-00532";
  public static final String APP_XXCSO1_00533    = "APP-XXCSO1-00533";
  public static final String APP_XXCSO1_00546    = "APP-XXCSO1-00546";
  public static final String APP_XXCSO1_00555    = "APP-XXCSO1-00555";
// 2009-04-08 [ST障害T1_0364] Add Start
  public static final String APP_XXCSO1_00558    = "APP-XXCSO1-00558";
  public static final String APP_XXCSO1_00559    = "APP-XXCSO1-00559";
// 2009-04-08 [ST障害T1_0364] Add End
// 2009-04-27 [ST障害T1_0708] Add Start
  public static final String APP_XXCSO1_00565    = "APP-XXCSO1-00565";
// 2009-04-27 [ST障害T1_0708] Add End
// 2009-05-26 [ST障害T1_1165] Add Start
  public static final String APP_XXCSO1_00571    = "APP-XXCSO1-00571";
// 2009-05-26 [ST障害T1_1165] Add End
// 2009-06-08 [ST障害T1_1307] Add Start
  public static final String APP_XXCSO1_00573    = "APP-XXCSO1-00573";
// 2009-06-08 [ST障害T1_1307] Add End
// 2009-06-16 [ST障害T1_1257] Add Start
  public static final String APP_XXCSO1_00574    = "APP-XXCSO1-00574";
// 2009-06-16 [ST障害T1_1257] Add End
// 2009-11-29 [E_本稼動_00106] Add Start
  public static final String APP_XXCSO1_00586    = "APP-XXCSO1-00586";
// 2009-11-29 [E_本稼動_00106] Add End
// 2010-01-12 [E_本稼動_00823] Add Start
  public static final String APP_XXCSO1_00589    = "APP-XXCSO1-00589";
// 2010-01-12 [E_本稼動_00823] Add End
// 2010-01-20 [E_本稼動_01212] Add Start
  public static final String APP_XXCSO1_00591    = "APP-XXCSO1-00591";
// 2010-01-20 [E_本稼動_01212] Add End
// 2010-02-09 [E_本稼動_01538] Mod Start
  public static final String APP_XXCSO1_00593    = "APP-XXCSO1-00593";
  public static final String APP_XXCSO1_00594    = "APP-XXCSO1-00594";
  public static final String APP_XXCSO1_00595    = "APP-XXCSO1-00595";
// 2010-02-09 [E_本稼動_01538] Mod End
// 2010-03-01 [E_本稼動_01678] Add Start
  public static final String APP_XXCSO1_00596    = "APP-XXCSO1-00596";
  public static final String APP_XXCSO1_00601    = "APP-XXCSO1-00601";
// 2010-03-01 [E_本稼動_01678] Add End
// 2010-03-01 [E_本稼動_01868] Add Start
  public static final String APP_XXCSO1_00602    = "APP-XXCSO1-00602";
// 2010-03-01 [E_本稼動_01868] Add End
// 2010-03-23 [E_本稼動_01942] Add Start
  public static final String APP_XXCSO1_00603    = "APP-XXCSO1-00603";
// 2010-03-23 [E_本稼動_01942] Add End
// 2011-01-06 Ver1.13 [E_本稼動_02498] Add Start
  public static final String APP_XXCSO1_00607    = "APP-XXCSO1-00607";
  public static final String APP_XXCSO1_00608    = "APP-XXCSO1-00608";
// 2011-01-06 Ver1.13 [E_本稼動_02498] Add End
// 2011-05-17 Ver1.15 [E_本稼動_02500] Add Start
  public static final String APP_XXCSO1_00613    = "APP-XXCSO1-00613";
// 2011-05-17 Ver1.15 [E_本稼動_02500] Add Start
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add Start
  public static final String APP_XXCSO1_00614    = "APP-XXCSO1-00614";
  public static final String APP_XXCSO1_00615    = "APP-XXCSO1-00615";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add End
// 2011-11-14 Ver1.17 [E_本稼動_08312] Add Start
  public static final String APP_XXCSO1_00617    = "APP-XXCSO1-00617";
  public static final String APP_XXCSO1_00618    = "APP-XXCSO1-00618";
  public static final String APP_XXCSO1_00619    = "APP-XXCSO1-00619";
// 2011-11-14 Ver1.17 [E_本稼動_08312] Add End
// 2012-06-12 [E_本稼動_09602] Add Start
  public static final String APP_XXCSO1_00639    = "APP-XXCSO1-00639";
// 2012-06-12 [E_本稼動_09602] Add End
// 2013-04-01 [E_本稼動_10413] Add Start
  public static final String APP_XXCSO1_00646    = "APP-XXCSO1-00646";
// 2013-04-01 [E_本稼動_10413] Add End
// 2013-04-19 [E_本稼動_09603] Add Start
  public static final String APP_XXCSO1_00648    = "APP-XXCSO1-00648";
// 2013-04-19 [E_本稼動_09603] Add End

  /*****************************************************************************
   * トークン名
   *****************************************************************************
   */
  public static final String TOKEN_RECORD        = "RECORD";
  public static final String TOKEN_ACTION        = "ACTION";
  public static final String TOKEN_COLUMN        = "COLUMN";
  public static final String TOKEN_INSTANCE_NAME = "INSTANCE_NAME";
  public static final String TOKEN_PROF_NAME     = "PROF_NAME";
  public static final String TOKEN_PROF_VALUE    = "PROF_VALUE";
  public static final String TOKEN_PARAM1        = "PARAM1";
  public static final String TOKEN_PARAM2        = "PARAM2";
  public static final String TOKEN_BUTTON        = "BUTTON";
  public static final String TOKEN_MODE          = "MODE";
  public static final String TOKEN_NO            = "NO";
  public static final String TOKEN_ITEM          = "ITEM";
  public static final String TOKEN_SIZE          = "SIZE";
  public static final String TOKEN_MAX_VAL       = "MAX_VAL";
  public static final String TOKEN_REF_OBJECT    = "REF_OBJECT";
  public static final String TOKEN_CRE_OBJECT    = "CRE_OBJECT";
  public static final String TOKEN_OBJECT        = "OBJECT";
  public static final String TOKEN_ERRMSG        = "ERRMSG";
  public static final String TOKEN_STRINGS       = "STRINGS";
  public static final String TOKEN_DIGIT         = "DIGIT";
  public static final String TOKEN_ENTRY         = "ENTRY";
  public static final String TOKEN_MAX_VALUE     = "MAX_VALUE";
  public static final String TOKEN_MAX_SIZE      = "MAX_SIZE";
  public static final String TOKEN_INDEX         = "INDEX";
  public static final String TOKEN_VALUES        = "VALUES";
  public static final String TOKEN_PERIOD        = "PERIOD";
  public static final String TOKEN_PARAM9        = "PARAM9";
  public static final String TOKEN_QUOTE_NUMBER  = "QUOTE_NUMBER";
  public static final String TOKEN_QUOTE_R_N     = "QUOTE_REVISION_NUMBER";
  public static final String TOKEN_PRICE         = "PRICE";
  public static final String TOKEN_REGION        = "REGION";
  public static final String TOKEN_VENDOR        = "VENDOR";
  public static final String TOKEN_MIN_VALUE     = "MIN_VALUE";
  public static final String TOKEN_FORWARD       = "FORWARD";
  public static final String TOKEN_ACCOUNT       = "ACCOUNT";
  public static final String TOKEN_CONC          = "CONC";
  public static final String TOKEN_CONCMSG       = "CONCMSG";
  public static final String TOKEN_EMSIZE        = "EMSIZE";
  public static final String TOKEN_ONEBYTE       = "ONEBYTE";
  public static final String TOKEN_ACCOUNTS      = "ACCOUNTS";
// 2011-01-06 Ver1.13 [E_本稼動_02498] Add Start
  public static final String TOKEN_BANK_NUM      = "BANK_NUM";
  public static final String TOKEN_BRANCH_NUM    = "BRANCH_NUM";
// 2011-01-06 Ver1.13 [E_本稼動_02498] Add End
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add Start
  public static final String TOKEN_BM_INFO       = "BM_INFO";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add End
// 2011-11-14 Ver1.17 [E_本稼動_08312] Add Start
  public static final String TOKEN_MARGIN_RATE   = "MARGIN_RATE";
// 2011-11-14 Ver1.17 [E_本稼動_08312] Add End
// 2014-01-31 Ver1.21 [E_本稼動_11397] Add Start
  public static final String TOKEN_CARD_SALE     = "CARD_SALE";
// 2014-01-31 Ver1.21 [E_本稼動_11397] Add End
  /*****************************************************************************
   * トークン値
   *****************************************************************************
   */
  public static final String
    TOKEN_VALUE_CREATE                 = "作成";
  public static final String
    TOKEN_VALUE_REGIST                 = "登録";
  public static final String
    TOKEN_VALUE_UPDATE                 = "更新";
  public static final String
    TOKEN_VALUE_DELETE                 = "削除";
  public static final String
    TOKEN_VALUE_SAVE                   = "保存";
  public static final String
    TOKEN_VALUE_DECISION               = "確定";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add Start
  public static final String
    TOKEN_VALUE_SAVE2                  = "保存2";
  public static final String
    TOKEN_VALUE_DECISION2              = "確定2";
  public static final String
    TOKEN_VALUE_SAVE3                  = "保存3";
  public static final String
    TOKEN_VALUE_DECISION3              = "確定3";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add End
// 2012-06-12 [E_本稼動_09602] Add Start
  public static final String
    TOKEN_VALUE_REJECT                 = "契約取消";
// 2012-06-12 [E_本稼動_09602] Add End
// 2013-04-01 [E_本稼動_10413] Add Start
  public static final String
    TOKEN_VALUE_WARN1                  = "警告1";
  public static final String
    TOKEN_VALUE_WARN2                  = "警告2";
  public static final String
    TOKEN_VALUE_WARN3                  = "警告3";
// 2013-04-01 [E_本稼動_10413] Add End
  public static final String
    TOKEN_VALUE_CSV_CREATE             = "CSVファイル作成";
  public static final String
    TOKEN_VALUE_LEAD_NUMBER            = "商談番号：";
  public static final String
    TOKEN_VALUE_ROUTE_NO               = "ルートNo";
  public static final String
    TOKEN_VALUE_ACCT_MONTHLY_PLAN      = "顧客別売上計画（月別）";
  public static final String
    TOKEN_VALUE_ACCT_DAILY_PLAN        = "顧客別売上計画（日別）";
  public static final String
    TOKEN_VALUE_DELIMITER1             = "の";
  public static final String
    TOKEN_VALUE_DAY                    = "日";
  public static final String
    TOKEN_VALUE_INIT_ACCT_SALES_TXN    = "顧客別売上計画情報の検索の初期化";
  public static final String
    TOKEN_VALUE_SALES_LINE             = "商談決定情報明細";
  public static final String
    TOKEN_VALUE_APPROVAL_REQUEST       = "承認依頼";
  public static final String
    TOKEN_VALUE_SEP_LEFT               = "（";
  public static final String
    TOKEN_VALUE_SEP_RIGHT              = "）";
  public static final String
    TOKEN_VALUE_QUOTE_NUMBER           = "見積番号：";
  public static final String
    TOKEN_VALUE_QUOTE_LINE             = "見積明細";
  public static final String
    TOKEN_VALUE_SP_DECISION_NUM        = "SP専決書番号：";
  public static final String
    TOKEN_VALUE_SP_DECISION_HEADER     = "SP専決ヘッダ";
  public static final String
    TOKEN_VALUE_SP_DECISION_LINE       = "SP専決明細";
  public static final String
    TOKEN_VALUE_SP_DECISION_CUST       = "SP専決顧客";
  public static final String
    TOKEN_VALUE_DELIMITER2             = "、";
  public static final String
    TOKEN_VALUE_FULL_VD_SP_DECISION    = "SP専決書";
  public static final String
    TOKEN_VALUE_INITIALIZE             = "初期化";
  public static final String
    TOKEN_VALUE_PV_DEF_VIEW_ID         = "ビューID";
  public static final String
    TOKEN_VALUE_PV                     = "パーソナライズ・ビュー";
  public static final String
    TOKEN_VALUE_PV_EXTRACT_TERM_DEF    = "汎用検索抽出条件定義";
  public static final String
    TOKEN_VALUE_DELIMITER3             = "：";
  public static final String
    TOKEN_VALUE_RESOURCE_NO            = "担当営業員";
  public static final String
    TOKEN_VALUE_COMPLETE               = "完了";
  public static final String
    TOKEN_VALUE_DISTRIBUTE_SALES_PLAN  = "按分";
  public static final String
    TOKEN_VALUE_CONTRACT_NUMBER        = "契約書番号：";
  public static final String
    TOKEN_VALUE_VENDOR_INFO            = "送付先情報";
  public static final String
    TOKEN_VALUE_CONTRACTOR_INFO        = "契約者(甲)情報";
  public static final String
    TOKEN_VALUE_REQUEST_ID             = "要求ID：";
  public static final String
    TOKEN_VALUE_ACCOUNT_NUMBER         = "顧客コード";
  public static final String
    TOKEN_VALUE_BASE_CODE              = "拠点コード";
  public static final String
    TOKEN_VALUE_YEAR_MONTH             = "計画年月";
  public static final String
    TOKEN_VALUE_CONTRACT_REGIST        = "自動販売機設置契約書";
  public static final String
    TOKEN_VALUE_SET_MODULE             = "モジュールの登録";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add Start
  public static final String
    TOKEN_VALUE_DELIMITER4             = "／";
  public static final String
    TOKEN_VALUE_DELIMITER5             = " ";
// 2011-06-06 Ver1.16 [E_本稼動_01963] Add End
  /*****************************************************************************
   * 機能ID
   *****************************************************************************
   */
  /****************/
  /** 標準画面系 **/
  /****************/
  public static final String FUNC_OA_HOME_PAGE         = "OAHOMEPAGE";
  public static final String FUNC_TASK_UPDATE_PG       = "CAC_TASK_UPDATE";
  public static final String ASN_OPPTYDETPG            = "ASN_OPPTYDETPG";
  public static final String ASN_MAIN_MENU             = "ASN_MAIN_MENU";

  /********************/
  /** 契約管理画面系 **/
  /********************/
  public static final String FUNC_CONTRACT_SEARCH_PG     = "XXCSO010001J_01";
  public static final String FUNC_CONTRACT_REGIST_PG     = "XXCSO010003J_01";

  /**********************/
  /** 商談系           **/
  /**********************/
  public static final String FUNC_SALES_REGIST_PG        = "XXCSO007003J_01";

  /**********************/
  /** 週次活動状況照会 **/
  /**********************/
  public static final String FUNC_WEEKLY_TASK_VIEW_PG    = "XXCSO008001J_01";

  /**********************/
  /** 物件管理画面系 **/
  /**********************/
  public static final String FUNC_INSTALL_BASE_PV_SEARCH_PG1
                                                         = "XXCSO012001J_01";
  public static final String FUNC_INSTALL_BASE_PV_SEARCH_PG2
                                                         = "XXCSO012001J_02";
  public static final String FUNC_PV_SEARCH_PG           = "XXCSO012001J_03";
  public static final String FUNC_PV_REGIST_PG           = "XXCSO012001J_04";

  /********************/
  /** 見積管理画面系 **/
  /********************/
  public static final String FUNC_QUOTE_SALES_REGIST_PG  = "XXCSO017001J_01";
  public static final String FUNC_QUOTE_STORE_REGIST_PG  = "XXCSO017002J_01";
  public static final String FUNC_QUOTE_SEARCH_PG        = "XXCSO017006J_01";

  /**********************/
  /** ルート管理画面系 **/
  /**********************/
  public static final String FUNC_VISIT_SALES_PLAN_REGIST_PG
                                                         = "XXCSO019001J_01";
  public static final String FUNC_SALES_PLAN_BULK_REGIST_PG
                                                         = "XXCSO019002J_01";
  public static final String FUNC_DEPT_MONTHLY_PLANS_REGIST_PG
                                                         = "XXCSO019003J_01";
  public static final String FUNC_RTN_RSRC_BULK_UPDATE_PG
                                                         = "XXCSO019009J_01";

  /**********************/
  /** SP専決画面系 **/
  /**********************/
  public static final String FUNC_SP_DECISION_SEARCH_PG1 = "XXCSO020001J_01";
  public static final String FUNC_SP_DECISION_SEARCH_PG2 = "XXCSO020001J_02";
  public static final String FUNC_SP_DECISION_REGIST_PG  = "XXCSO020001J_03";

  /**********************/
  /** IB画面 **/
  /**********************/
  public static final String FUNC_CSI_SEARCH_PROD        = "CSI_SEARCH_PROD";

  /*****************************************************************************
   * プロファイルオプション値（共通）
   *****************************************************************************
   */
  public static final String VO_MAX_FETCH_SIZE    = "VO_MAX_FETCH_SIZE";
  public static final String XXCSO1_CLIENT_ENCODE = "XXCSO1_CLIENT_ENCODE";

  /*****************************************************************************
   * URLパラメータ（共通）
   *****************************************************************************
   */
  public static final String EXECUTE_MODE      = "ExecuteMode";
  public static final String TRANSACTION_KEY1  = "TransactionKey1";
  public static final String TRANSACTION_KEY2  = "TransactionKey2";
  public static final String TRANSACTION_KEY3  = "TransactionKey3";

  /*****************************************************************************
   * 操作モード
   *****************************************************************************
   */
  public static final String OPERATION_MODE_NORMAL  = "NORMAL";
  public static final String OPERATION_MODE_REQUEST = "REQUEST";
}
