/*============================================================================
* ファイル名 : XxcsoSalesNotifyFullVOImpl
* 概要説明   : 商談決定情報通知者リスト登録用ビュークラス
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
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.Row;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * 商談決定情報明細通知者リストを登録するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifyFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifyFullVOImpl()
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

    XxcsoSalesNotifyFullVORowImpl notifyRow
      = (XxcsoSalesNotifyFullVORowImpl)this.first();

    String insertSortCode
      = ((XxcsoSalesNotifyFullVORowImpl)row).getPositionSortCode();
    String insertEmpNum
      = ((XxcsoSalesNotifyFullVORowImpl)row).getEmployeeNumber();
    XxcsoUtils.debug(txn, "insert Sort Code = " + insertSortCode);
    XxcsoUtils.debug(txn, "insert Emp Num   = " + insertEmpNum);
    
    while ( notifyRow != null )
    {
      String currentSortCode = notifyRow.getPositionSortCode();
      String currentEmpNum   = notifyRow.getEmployeeNumber();

      XxcsoUtils.debug(txn, "current Sort Code = " + currentSortCode);
      XxcsoUtils.debug(txn, "current Emp Num   = " + currentEmpNum);
      
      if ( insertSortCode != null && ! "".equals(insertSortCode) )
      {
        if ( currentSortCode != null && ! "".equals(currentSortCode) )
        {
          int sortCodeCompare = insertSortCode.compareTo(currentSortCode);
          XxcsoUtils.debug(
            txn
           ,"compare insert current position sort code = " + sortCodeCompare
          );
          
          if ( sortCodeCompare == 0 )
          {
            int empNumCompare = insertEmpNum.compareTo(currentEmpNum);
            XxcsoUtils.debug(
              txn
             ,"compare insert current employee number = " + empNumCompare
            );
            
            if ( empNumCompare > 0 )
            {
              this.next();
            }
            break;
          }
          
          if ( sortCodeCompare < 0 )
          {
            break;
          }
        }
      }

      notifyRow = (XxcsoSalesNotifyFullVORowImpl)this.next();
    }
    
    super.insertRow(row);

    XxcsoUtils.debug(txn, "[END]");
  }
}