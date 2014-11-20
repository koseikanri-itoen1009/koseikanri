/*============================================================================
* �t�@�C���� : XxcsoAcctSalesPlansUtils
* �T�v����   : �K��E����v���ʁ@���ʃ��[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.jbo.domain.Date;
import java.sql.SQLException;
import oracle.sql.DATE;

public class XxcsoAcctSalesPlansUtils 
{
  /*****************************************************************************
   * ����v��g�����U�N�V����������
   * 
   * @param txn             OADBTransaction
   * @param baseCode        ���_�R�[�h
   * @param accountNumber   �ڋq�R�[�h
   * @param planYear        �v��N
   * @param planMonth       �v�挎
   *****************************************************************************
   */
  public static void initTransaction(
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
    sql.append("  xxcso_acct_sales_plans_pkg.init_transaction(");
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
   * �I�����C�����t�擾
   * @param txn         OADBTransaction
   *****************************************************************************
   */
  public static Date getOnlineSysdate(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT xxcso_util_common_pkg.get_online_sysdate AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    DATE nowDate = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getDATE("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getOnlineSysdate"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return new Date(nowDate);
  }

  /*****************************************************************************
   * �I�����C���N���̂P���擾
   * @param txn         OADBTransaction  txn
   *****************************************************************************
   */
  public static Date getOnlineSysdateFirst(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT TRUNC(");
    sql.append("         xxcso_util_common_pkg.get_online_sysdate");
    sql.append("        ,'MM'");
    sql.append("       ) AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    DATE nowDate = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getDATE("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getOnlineSysDateFirst"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return new Date(nowDate);
  }

  /*****************************************************************************
   * �V�X�e�������̎擾
   * @param txn         OADBTransaction  txn
   *****************************************************************************
   */
  public static String getSysdateTimeString(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT TO_CHAR(");
    sql.append("         SYSDATE");
    sql.append("        ,'YYYYMMDDHH24MISS'");
    sql.append("       ) AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    String nowDate = "";
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getString("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getSysdateTimeString"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return nowDate;
  }

  /*****************************************************************************
   * �c�ƈ�����
   *****************************************************************************
   */
  public static boolean isSalesPerson(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT xxcso_util_common_pkg.chk_responsibility(");
    sql.append("         fnd_global.user_id");
    sql.append("        ,fnd_global.resp_id");
    sql.append("        ,'1') AS readonly_value");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    String readonlyValue = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        readonlyValue = rslt.getString(1);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"isSalesPerson"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    if ( "TRUE".equals(readonlyValue) )
    {
      return true;
    }
    return false;
  }

}