package itoen.oracle.apps.xxwip.poplist.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* ファイル名 : SlitVOImpl
* 概要説明   : 投入口ポップリストビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-19 1.0  二瓶大輔     新規作成
*============================================================================
*/
public class SlitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public SlitVOImpl()
  {
  }
  /*****************************************************************************
   * 投入口ポップリスト取得SQLを実行します
   * @param routingId 工順ID
   ****************************************************************************/
  public void initQuery(String routingId) {
    setWhereClauseParams(null); // Always reset
    setWhereClauseParam(0, routingId);
    executeQuery();
  }
}