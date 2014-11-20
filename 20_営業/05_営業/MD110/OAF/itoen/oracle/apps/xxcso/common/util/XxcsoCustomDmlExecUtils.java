/*============================================================================
* �t�@�C���� : XxcsoCustomDmlExecUtils
* �T�v����   : �J�X�^��DML���s���[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.jbo.AttributeDef;
import oracle.jbo.server.EntityDefImpl;
import oracle.sql.Datum;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import java.sql.SQLException;
import java.util.ArrayList;

/*******************************************************************************
 * ���삵��DML�������s���邽�߂̃N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCustomDmlExecUtils 
{
  /*****************************************************************************
   * INSERT�����ł��B
   * @param txn       OADBTransaction�C���X�^���X
   * @param tableName INSERT����e�[�u����
   * @param entity    INSERT�Ώۂ̃G���e�B�e�B�I�u�W�F�N�g
   * @param entityDef INSERT�Ώۂ̃G���e�B�e�B��`�I�u�W�F�N�g
   * @throws SQLException
   *****************************************************************************
   */
  public static void insertRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    insertRow(txn, tableName, entity, entityDef,null);
  }
  
  /*****************************************************************************
   * INSERT�����ł��B
   * @param txn       OADBTransaction�C���X�^���X
   * @param tableName INSERT����e�[�u����
   * @param entity    INSERT�Ώۂ̃G���e�B�e�B�I�u�W�F�N�g
   * @param entityDef INSERT�Ώۂ̃G���e�B�e�B��`�I�u�W�F�N�g
   * @param leaves    INSERT�����Ȃ����ڂ�INDEX���X�g
   * @throws SQLException
   *****************************************************************************
   */
  public static void insertRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
   ,int[]           leaves
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("INSERT INTO ").append(tableName).append("(");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    int columnIndex   = 0;
    boolean commaFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(attrDefs[i].getColumnName());
    }
    
    sql.append(")VALUES(");
    commaFlag = false;

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(":").append(columnIndex);
    }
    sql.append(")");
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      Object object = entity.getAttributeInternal(attrDefs[i].getIndex());
      int sqlType   = attrDefs[i].getSQLType();

      bindObject(txn, stmt, columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * UPDATE�����ł��B
   * @param txn       OADBTransaction�C���X�^���X
   * @param tableName UPDATE����e�[�u����
   * @param entity    UPDATE�Ώۂ̃G���e�B�e�B�I�u�W�F�N�g
   * @param entityDef UPDATE�Ώۂ̃G���e�B�e�B��`�I�u�W�F�N�g
   * @param leaves    UPDATE�����Ȃ����ڂ�INDEX���X�g
   * @throws SQLException
   *****************************************************************************
   */
  public static void updateRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    updateRow(txn, tableName, entity, entityDef, null);
  }
  
  /*****************************************************************************
   * UPDATE�����ł��B
   * @param txn       OADBTransaction�C���X�^���X
   * @param tableName UPDATE����e�[�u����
   * @param entity    UPDATE�Ώۂ̃G���e�B�e�B�I�u�W�F�N�g
   * @param entityDef UPDATE�Ώۂ̃G���e�B�e�B��`�I�u�W�F�N�g
   * @param leaves    UPDATE�����Ȃ����ڂ�INDEX���X�g
   * @throws SQLException
   *****************************************************************************
   */
  public static void updateRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
   ,int[]           leaves
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("UPDATE ").append(tableName).append(" SET ");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    ArrayList pkAttrDefList = new ArrayList();
    int columnIndex   = 0;
    boolean commaFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( attrDefs[i].isPrimaryKey() )
      {
        pkAttrDefList.add(attrDefs[i]);
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(attrDefs[i].getColumnName());
      sql.append(" = :");
      sql.append(columnIndex);
    }
    
    sql.append(" WHERE ");
    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      sql.append(attrDef.getColumnName()).append(" = :");
      sql.append(columnIndex);
    }
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( attrDefs[i].isPrimaryKey() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      Object object = entity.getAttributeInternal(attrDefs[i].getIndex());
      int sqlType   = attrDefs[i].getSQLType();

       bindObject(txn, stmt, columnIndex, object, sqlType);
   }

    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      Object object = entity.getAttributeInternal(attrDef.getIndex());
      int sqlType = attrDef.getSQLType();

      bindObject(txn, stmt, columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * DELETE�����ł��B
   * @param txn       OADBTransaction�C���X�^���X
   * @param tableName DELETE����e�[�u����
   * @param entity    DELETE�Ώۂ̃G���e�B�e�B�I�u�W�F�N�g
   * @param entityDef DELETE�Ώۂ̃G���e�B�e�B��`�I�u�W�F�N�g
   * @throws SQLException
   *****************************************************************************
   */
  public static void deleteRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("DELETE ").append(tableName).append(" WHERE ");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    ArrayList pkAttrDefList = new ArrayList();
    int columnIndex = 0;
    boolean andFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isPrimaryKey() )
      {
        continue;
      }

      pkAttrDefList.add(attrDefs[i]);
      
      columnIndex++;
      
      if ( andFlag )
      {
        sql.append(" AND ");
      }
      andFlag = true;
      sql.append(attrDefs[i].getColumnName());
      sql.append(" = :").append(columnIndex);
    }
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      Object object = entity.getAttributeInternal(attrDef.getIndex());
      int sqlType   = attrDef.getSQLType();

      bindObject(txn, stmt,columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �o�C���h�����ł��B
   * @param stmt      OracleCallableStatement�C���X�^���X
   * @param index     �o�C���h����ꏊ
   * @param object    �o�C���h����l
   * @param sqlType   �o�C���h����^
   * @throws SQLException
   *****************************************************************************
   */
  private static void bindObject(
    OADBTransaction         txn
   ,OracleCallableStatement stmt
   ,int                     index
   ,Object                  object
   ,int                     sqlType
  ) throws SQLException
  {
    if ( object == null )
    {
      XxcsoUtils.debug(txn, "bind [" + index + "] = null");
      stmt.setNull(index, sqlType);
    }
    else
    {
      XxcsoUtils.debug(txn, "bind [" + index + "] = " + object.toString());
      if ( object instanceof Datum )
      {
        stmt.setOracleObject(index, (Datum)object);          
      }
      else
      {
        stmt.setObject(index, object, sqlType);
      }
    }    
  }
}