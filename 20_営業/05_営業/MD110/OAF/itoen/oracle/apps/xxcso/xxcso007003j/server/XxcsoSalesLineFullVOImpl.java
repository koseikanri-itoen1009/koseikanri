/*============================================================================
* ファイル名 : XxcsoSalesLineFullVOImpl
* 概要説明   : 商談決定情報明細登録／更新用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.Row;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * 商談決定情報明細情報を登録／更新するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLineFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLineFullVOImpl()
  {
  }


  /*****************************************************************************
   * LOVボタンによるレコード追加処理です。
   * @see interface oracle.jbo.RowIterator.insertRowAtRangeIndex
   *****************************************************************************
   */
  public void insertRowAtRangeIndex(int index, Row row)
  {
    OAApplicationModule am = (OAApplicationModule)getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    last();
    next();
    super.insertRow(row);

    XxcsoUtils.debug(txn, "[END]");
  }
}