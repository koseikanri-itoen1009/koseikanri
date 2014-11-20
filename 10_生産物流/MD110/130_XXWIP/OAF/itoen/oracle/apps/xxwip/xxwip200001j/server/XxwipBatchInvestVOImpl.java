package itoen.oracle.apps.xxwip.xxwip200001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* ファイル名 : XxwipBatchInvestVOImpl
* 概要説明   : 生産投入原料ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  二瓶大輔     新規作成
*============================================================================
*/
public class XxwipBatchInvestVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipBatchInvestVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchBatchId - 検索キー
   ****************************************************************************/
  public void initQuery(String searchBatchId)
  {
    setWhereClauseParam(0, searchBatchId);
    setWhereClauseParam(1, searchBatchId);
    executeQuery();
  }
}