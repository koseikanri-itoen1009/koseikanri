/*============================================================================
* ファイル名 : XxwshLineVOImpl
* 概要説明   : 入出荷実績ロット入力画面ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 入出荷実績ロット入力画面ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxwshLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshLineVOImpl()
  {
  }
  
  /*****************************************************************************
   * VOの初期化を行います。
   * @param orderLineId  - 受注明細アドオンID
   * @param calledKbn    - 呼出画面区分
   ****************************************************************************/
  public void initQuery(
    String      orderLineId,
    String      calledKbn
    )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, calledKbn);
    setWhereClauseParam(1, calledKbn);
    setWhereClauseParam(2, calledKbn);
    setWhereClauseParam(3, orderLineId);
  
    // SELECT文実行
    executeQuery();
  }
}