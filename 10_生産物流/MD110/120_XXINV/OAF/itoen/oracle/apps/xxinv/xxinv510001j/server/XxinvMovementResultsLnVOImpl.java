/*============================================================================
* ファイル名 : XxinvMovementResultsLnVO
* 概要説明   : 入出庫実績明細:検索ビューオブジェクト
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-18 1.0  大橋孝郎     新規作成
* 2008-08-21 1.1  山本恭久     内部変更#167対応
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 検索ビューオブジェクトです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */

public class XxinvMovementResultsLnVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsLnVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchHdrId 検索パラメータヘッダID
   * @param productFlg  製品識別区分
   ****************************************************************************/
   public void initQuery(
    String  searchHdrId,
    String  productFlg
   )
   {
     // 初期化
    setWhereClauseParams(null);

    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, productFlg);
    setWhereClauseParam(1, productFlg);
    setWhereClauseParam(2, productFlg);
    setWhereClauseParam(3, productFlg);
// 2008/08/21 v1.1 Y.Yamamoto Mod Start
//    setWhereClauseParam(4, productFlg);
//    setWhereClauseParam(5, searchHdrId);
    setWhereClauseParam(4, searchHdrId);
// 2008/08/21 v1.1 Y.Yamamoto Mod End

    // SELECT文実行
    executeQuery();
   }
}