/*============================================================================
* ファイル名 : XxinvMovementResultsLnVO
* 概要説明   : 入出庫実績明細:検索ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-18 1.0  大橋孝郎     新規作成
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
   ****************************************************************************/
   public void initQuery(
    String  searchHdrId         // 検索パラメータヘッダID
   )
   {
     // 初期化
    setWhereClauseParams(null);

    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchHdrId);

    // SELECT文実行
    executeQuery();
   }
}