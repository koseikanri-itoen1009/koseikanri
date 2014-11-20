/*============================================================================
* ファイル名 : XxpoProvisionRtnMakeTotalVOImpl
* 概要説明   : 支給返品作成合計ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-02 1.0  熊本和郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 支給返品作成合計ビューオブジェクトクラスです。
 * @author  ORACLE 熊本 和郎
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeTotalVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(Number orderHeaderId)
  {
    // 条件設定
    setWhereClauseParam(0, orderHeaderId);

    // 検索実行
    executeQuery();

  }


}