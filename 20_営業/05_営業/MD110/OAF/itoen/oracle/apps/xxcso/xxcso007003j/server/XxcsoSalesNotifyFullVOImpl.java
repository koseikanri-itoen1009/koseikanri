/*============================================================================
* �t�@�C���� : XxcsoSalesNotifyFullVOImpl
* �T�v����   : ���k������ʒm�҃��X�g�o�^�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.Row;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * ���k�����񖾍גʒm�҃��X�g��o�^���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
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
   * LOV�{�^���ɂ�郌�R�[�h�ǉ������ł��B
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