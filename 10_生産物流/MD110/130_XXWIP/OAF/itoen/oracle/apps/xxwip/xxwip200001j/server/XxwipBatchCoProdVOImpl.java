/*============================================================================
* ファイル名 : XxwipBatchCoProdVOImpl
* 概要説明   : 副産物情報ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 副産物情報ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxwipBatchCoProdVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipBatchCoProdVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchBatchId - 検索キー
   ****************************************************************************/
  public void initQuery(String searchBatchId)
  {
    setWhereClauseParam(0, searchBatchId);
    executeQuery();
  }
}