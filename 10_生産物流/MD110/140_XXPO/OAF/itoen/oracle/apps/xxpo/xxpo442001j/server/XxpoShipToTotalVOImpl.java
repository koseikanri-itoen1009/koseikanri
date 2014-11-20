/*============================================================================
* ファイル名 : XxpoShipToTotalVOImpl
* 概要説明   : 入庫実績入力明細合計ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  新藤義勝     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * 入庫実績入力明細合計ビューオブジェクトクラスです。
 * @author  ORACLE 新藤 義勝
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShipToTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShipToTotalVOImpl()
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