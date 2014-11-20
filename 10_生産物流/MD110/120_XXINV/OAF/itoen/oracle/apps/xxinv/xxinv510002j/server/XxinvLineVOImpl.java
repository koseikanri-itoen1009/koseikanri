/*============================================================================
* ファイル名 : XxinvLineVOImpl
* 概要説明   : 出庫・入庫ロット明細画面(移動指示明細)ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 出庫・入庫ロット明細画面(移動指示明細)ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxinvLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvLineVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param movLineId     - 移動明細ID
   * @param productFlg    - 製品識別区分
   ****************************************************************************/
  public void initQuery(
    String      movLineId,
    String      productFlg
    )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, productFlg);
    setWhereClauseParam(1, productFlg);
    setWhereClauseParam(2, productFlg);
    setWhereClauseParam(3, movLineId);
  
    // SELECT文実行
    executeQuery();
  }
}