/*============================================================================
* ファイル名 : XxpoPoInquiryLineVOImpl
* 概要説明   : 発注・受入照会画面/発注受入明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-07 1.0  伊藤ひとみ   新規作成  内部変更要求対応(#41,48)
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
/***************************************************************************
 * 発注・受入照会画面/発注受入明細ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquiryLineVOImpl()
  {
  }
  
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchStatusCode     - 発注ステータス
   * @param searchDeliveryDate   - 納入日
   * @param searchHeaderId       - 発注ヘッダID
   ****************************************************************************/
  public void initQuery( 
    String searchStatusCode,
    Date   searchDeliveryDate,
    String searchHeaderId
  )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchStatusCode);
    setWhereClauseParam(1, searchStatusCode);
    setWhereClauseParam(2, searchStatusCode);
    setWhereClauseParam(3, searchStatusCode);
    setWhereClauseParam(4, searchDeliveryDate);
    setWhereClauseParam(5, searchDeliveryDate);
    setWhereClauseParam(6, searchDeliveryDate);
    setWhereClauseParam(7, searchDeliveryDate);
    setWhereClauseParam(8, searchDeliveryDate);
    setWhereClauseParam(9, searchDeliveryDate);
    setWhereClauseParam(10, searchHeaderId);
    
    // SELECT文実行
    executeQuery();
  }
}