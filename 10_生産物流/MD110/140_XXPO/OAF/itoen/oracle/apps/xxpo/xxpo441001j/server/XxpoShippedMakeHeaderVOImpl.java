/*============================================================================
* ファイル名 : XxpoShippedMakeHeaderVOImpl
* 概要説明   : 出庫実績入力ヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-28 1.0  山本恭久     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 出庫実績入力ヘッダビューオブジェクトクラスです。
 * @author  ORACLE 山本 恭久
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param reqNo - 依頼No
   ****************************************************************************/
  public void initQuery(String reqNo)
  {
    setWhereClauseParam(0, reqNo);
    // 検索実行
    executeQuery();
  }
}