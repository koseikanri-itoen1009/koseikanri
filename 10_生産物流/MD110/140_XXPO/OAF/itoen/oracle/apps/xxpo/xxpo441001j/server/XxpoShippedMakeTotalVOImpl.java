/*============================================================================
* ファイル名 : XxpoShippedMakeTotalVOImpl
* 概要説明   : 出庫実績入力合計ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  山本恭久     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * 出庫実績入力合計ビューオブジェクトクラスです。
 * @author  ORACLE 山本 恭久
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedMakeTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedMakeTotalVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(Number orderHeaderId)
  {
    setWhereClauseParam(0, orderHeaderId);
    // 検索実行
    executeQuery();
  }
}