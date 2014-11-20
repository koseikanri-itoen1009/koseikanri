/*============================================================================
* ファイル名 : XxpoPoInquirySumVOImpl
* 概要説明   : 発注・受入照会画面/発注受入合計ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-13 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 発注・受入照会画面/発注受入合計ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquirySumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquirySumVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchStatusCode     - 発注ステータス
   * @param searchHeaderId       - 発注ヘッダID
   ****************************************************************************/
  public void initQuery(
    String searchStatusCode,
    String searchHeaderId
    )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchStatusCode);
    setWhereClauseParam(1, searchStatusCode);
    setWhereClauseParam(2, searchStatusCode);
    setWhereClauseParam(3, searchStatusCode);
    setWhereClauseParam(4, searchHeaderId);
    
    // SELECT文実行
    executeQuery();
  }
}