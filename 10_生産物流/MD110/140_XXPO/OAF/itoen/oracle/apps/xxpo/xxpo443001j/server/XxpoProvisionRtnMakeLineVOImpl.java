/*============================================================================
* ファイル名 : XxpoProvisionRtnMakeLineVOImpl
* 概要説明   : 支給返品作成明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  熊本和郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 支給返品作成明細ビューオブジェクトクラスです。
 * @author  ORACLE 熊本 和郎
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeLineVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param exeType       - 起動タイプ ※支給返品では未使用
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(
    String exeType,
    Number orderHeaderId
  )
  {
    int i = 0;
    setWhereClauseParam(i, orderHeaderId);
    // 検索実行
    executeQuery();
  }
}