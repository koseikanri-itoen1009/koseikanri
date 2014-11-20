/*============================================================================
* ファイル名 : XxpoProvisionInstMakeTotalVOImpl
* 概要説明   : 支給指示作成合計ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-14 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * 支給指示作成合計ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionInstMakeTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionInstMakeTotalVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(Number orderHeaderId)
  {
    // 初期化
    setWhereClauseParams(null);
    setWhereClauseParam(0, orderHeaderId);
    // 検索実行
    executeQuery();
  }
}