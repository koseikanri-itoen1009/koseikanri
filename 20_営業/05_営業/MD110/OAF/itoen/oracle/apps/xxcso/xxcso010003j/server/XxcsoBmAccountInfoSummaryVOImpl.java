/*============================================================================
* ファイル名 : XxcsoBmAccountInfoSummaryVOImpl
* 概要説明   : BM顧客情報取得ビューオブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;

/*******************************************************************************
 * BM顧客情報取得ビューオブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBmAccountInfoSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBmAccountInfoSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param bm1VendorCode    BM1送付先コード
   * @param bm2VendorCode    BM2送付先コード
   * @param bm3VendorCode    BM3送付先コード
   * @param installAccountId 設置先顧客ID
   *****************************************************************************
   */
  public void initQuery(
    String bm1VendorCode
   ,String bm2VendorCode
   ,String bm3VendorCode
   ,Number installAccountId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int idx = 0;
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, installAccountId);

    executeQuery();
  }

}