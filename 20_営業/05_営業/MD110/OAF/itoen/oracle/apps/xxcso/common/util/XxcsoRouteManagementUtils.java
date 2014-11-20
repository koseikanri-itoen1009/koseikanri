/*============================================================================
* �t�@�C���� : XxcsoRouteManagementUtils
* �T�v����   : �y�A�h�I���F�c�ƁE�c�Ɨ̈�z���[�g�Ǘ����ʃ��[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-05 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import java.sql.SQLException;

/*******************************************************************************
 * �A�h�I���F���[�g�Ǘ����ʃ��[�e�B���e�B�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRouteManagementUtils 
{
  private Object SYNC_OBJECT = new Object();
  private static XxcsoRouteManagementUtils _instance = null;

  /*****************************************************************************
   * ����v��g�����U�N�V����������
   * @param txn           OADBTransaction�C���X�^���X
   * @param baseCode      ���_�R�[�h
   * @param accountNumber �ڋq�R�[�h
   * @param planYear      �v��N
   * @param planYear      �v�挎
   *****************************************************************************
   */
  public void initTransaction(
    OADBTransaction  txn
   ,String           baseCode
   ,String           accountNumber
   ,String           planYear
   ,String           planMonth
  )
  {
    StringBuffer sql = new StringBuffer(100);
    int index = 0;
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.init_transaction(");
    sql.append("    iv_base_code      => :").append(++index);
    sql.append("   ,iv_account_number => :").append(++index);
    sql.append("   ,iv_year_month     => :").append(++index);
    sql.append("   ,ov_errbuf         => :").append(++index);
    sql.append("   ,ov_retcode        => :").append(++index);
    sql.append("   ,ov_errmsg         => :").append(++index);
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      index = 0;
      stmt.setString(++index, baseCode);
      stmt.setString(++index, accountNumber);
      stmt.setString(++index, (planYear + planMonth));

      int outIndex = index;
      
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      
      stmt.execute();

      String errorBuffer  = stmt.getString(++outIndex);
      String errorCode    = stmt.getString(++outIndex);
      String errorMessage = stmt.getString(++outIndex);
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_INIT_ACCT_SALES_TXN
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }
  }

  /*****************************************************************************
   * ����v��(�����ڋq)�g�����U�N�V����������
   * @param txn             OADBTransaction�C���X�^���X
   * @param baseCode        ���_�R�[�h
   * @param employeeNumber  �]�ƈ��ԍ�
   * @param targetYear      �Ώ۔N
   * @param targetYear      �Ώی�
   *****************************************************************************
   */
  public void initTransactionBulk(
    OADBTransaction  txn
   ,String           baseCode
   ,String           employeeNumber
   ,String           targetYear
   ,String           targetMonth
  )
  {
    StringBuffer sql = new StringBuffer(100);
    int index = 0;
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.init_transaction_bulk(");
    sql.append("    iv_base_code       => :").append(++index);
    sql.append("   ,iv_employee_number => :").append(++index);
    sql.append("   ,iv_year_month      => :").append(++index);
    sql.append("   ,ov_errbuf          => :").append(++index);
    sql.append("   ,ov_retcode         => :").append(++index);
    sql.append("   ,ov_errmsg          => :").append(++index);
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      index = 0;
      stmt.setString(++index, baseCode);
      stmt.setString(++index, employeeNumber);
      stmt.setString(++index, (targetYear + targetMonth));

      int outIndex = index;
      
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      
      stmt.execute();

      String errorBuffer  = stmt.getString(++outIndex);
      String errorCode    = stmt.getString(++outIndex);
      String errorMessage = stmt.getString(++outIndex);
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_INIT_ACCT_SALES_TXN
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }
  }

  /*****************************************************************************
   * ���[�g�Ǘ��g�����U�N�V�����R�~�b�g
   * @param txn           OADBTransaction�C���X�^���X
   *****************************************************************************
   */
  public void commitTransaction(
    OADBTransaction txn
  )
  {
    synchronized( SYNC_OBJECT )
    {
      txn.commit();
    }
  }

  /*****************************************************************************
   * ���[�g�Ǘ����ʃ��[�e�B���e�B�C���X�^���X�擾
   *****************************************************************************
   */
  public static XxcsoRouteManagementUtils getInstance()
  {
    return _instance;
  }
  
  /*****************************************************************************
   * ���[�g�Ǘ����ʃ��[�e�B���e�B�C���X�^���X������
   *****************************************************************************
   */
  static
  {
    _instance = new XxcsoRouteManagementUtils();
  }
  
  /*****************************************************************************
   * �f�t�H���g�R���X�g���N�^
   *****************************************************************************
   */
  private XxcsoRouteManagementUtils()
  {
  }
}