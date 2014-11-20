/*============================================================================
* ファイル名 : XxpoVendorSupplyMakeVOImpl
* 概要説明   : 外注出来高報告:登録ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-01-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 外注出来高報告:登録ビューオブジェクトクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyMakeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyMakeVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchTxnsId         - 検索パラメータ実績ID
   ****************************************************************************/
  public void initQuery(
    String  searchTxnsId         // 検索パラメータ実績ID
   )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchTxnsId);
  
    // SELECT文実行
    executeQuery();
  }
}