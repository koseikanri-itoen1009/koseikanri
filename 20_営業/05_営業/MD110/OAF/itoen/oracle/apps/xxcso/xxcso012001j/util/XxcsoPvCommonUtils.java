/*============================================================================
* ファイル名 : XxcsoPvCommonUtils
* 概要説明   : 物件汎用検索／パーソナライズビュー共通クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.util;

import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

/*******************************************************************************
 * 物件汎用検索／パーソナライズビュー共通クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvCommonUtils 
{

  /*****************************************************************************
   * 物件情報汎用検索画面PG名判定処理
   * @param  pvDispMode 汎用検索表示区分
   * @return PG名
   *****************************************************************************
   */
  public static String getInstallBasePgName(String pvDispMode)
  {
    String pgName = "";
    if ( XxcsoPvCommonConstants.PV_DISPLAY_MODE_1.equals(pvDispMode) )
    {
      pgName = XxcsoConstants.FUNC_INSTALL_BASE_PV_SEARCH_PG1;
    }
    else
    {
      pgName = XxcsoConstants.FUNC_INSTALL_BASE_PV_SEARCH_PG2;
    }
    return pgName;
  }
  
  /*****************************************************************************
   * 画面遷移に必要なパラメータを作成します
   * @param execMode   実行区分
   * @param pvDispMode 汎用検索表示区分
   * @param viewId     ビューID
   * @return URLに引き渡すパラメータ(HashMap)
   *****************************************************************************
   */
  public static HashMap createParam(
    String execMode
   ,String pvDispMode
   ,String viewId
  )
  {
    HashMap map = new HashMap(3);
    map.put(XxcsoConstants.EXECUTE_MODE, execMode);       // 実行区分
    map.put(XxcsoConstants.TRANSACTION_KEY1, pvDispMode); // 汎用検索使用モード
    map.put(XxcsoConstants.TRANSACTION_KEY2, viewId);     // ビューID
    return map;
  }



}