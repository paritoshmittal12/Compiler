/*
----------------------------------------------------------------------------------------------------------------------------------
|				CODE contains functions for Symantic Analysis of a given Sub-C code.											 |
----------------------------------------------------------------------------------------------------------------------------------				
*/

/*
Global Tables are maintained to keep track of everything in the code.

Function tables contains function pointers that contain param_list and other details for each function.

list_var contains all variables that being defined or used. It contains the value and scope of each variable.

Variable overloading is allowed as scope is different.
*/


#include <iostream>
#include <list>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <vector>
#include <sstream>
using namespace std;


int temp_count = 0;
enum data_type { INT1, FLOAT1, CHAR1, BOOL1, VOID1, STRUCT1, NONE, ERROR };
enum var_type { SIMPLE , ARRAY};

union value{
	int a;
	float b;
	char c;
	bool d;
};

struct Node {
	string name;
	string str_name;
	data_type type;
	var_type vtype;
	value val;
	int begin;
	int quad;

	Node () {
		val.a=-1;
	}
	vector<int> next;
	int falselist;
	 int place_int;
	 int offset_int;
	 int result_int;
};

typedef struct variable{
	string name;
	data_type dtype;
	var_type vtype;
	int ref;
	value val;
	int level;
	struct structure *str_ptr;
	vector<int> dimlist;

	variable() {}

   variable(string name1 ,data_type type1 ,var_type ele_type1 ,int level1 )
   {
       name = name1;
       dtype = type1;
	   vtype = ele_type1;
       level = level1;


   }
}list_var ;

typedef struct structure
{
	string name;
	vector<list_var> mem_list;
	int level;
	structure (){}

	structure(string name1, int level1)
	{
		name = name1;
		level = level1;
	}
	
} list_struct;


typedef struct function {
	string func_name;
	data_type func_type;
	vector<list_var> param_list;
	vector<list_var> var_list;
	int num_param;
	int defined;

	function(){}
    function(string name1 ,data_type return_type1)
    {
        func_name = name1;
        func_type = return_type1;
    }
} entry;



list_struct* search_struct(std::vector<list_struct> *struct_table, string name1)
{
	list_struct *temp = NULL;
	for(int i=0; i<(*struct_table).size(); i++)
	{
		if((*struct_table)[i].name == name1)
		{
			temp = &(*struct_table)[i];
			return temp;
		}
	}
	return temp;
}

list_var* search_str_var(vector<variable> struct_var_table, string var_name)
{
	list_var *temp=NULL;
	for(int i=0; i<struct_var_table.size(); i++)
	{
		if(struct_var_table[i].name == var_name)
		{
			temp = &struct_var_table[i];
			return temp;
		}
	}
	return temp;
}

//searches function in Function table

entry* search_function(std::vector<entry> *function_table, string name)
{
    for(int i=0; i<(*function_table).size(); i++)
    {
            if((*function_table)[i].func_name == name)
            {
            		return &((*function_table)[i]);
            }
    }
   
    return NULL;
}

//searches paramaeter in param_list of a function
list_var* search_param(string param_name,entry* fnptr)
{
	if(fnptr == NULL)
		return NULL;
	for(int i=0; i<fnptr->param_list.size(); i++)
    {
            if(fnptr->param_list[i].name == param_name)
            {
                    return &(fnptr->param_list[i]);
            }
    }
   
    return NULL;

}

list_var* search_param1(string param_name,var_type vtype, int dimno,entry* fnptr)
{
	if(fnptr == NULL)
		return NULL;
	for(int i=0; i<fnptr->param_list.size(); i++)
    {
            if(fnptr->param_list[i].name == param_name  && vtype==fnptr->param_list[i].vtype)
            {
            	if(vtype==ARRAY){
            		if(fnptr->param_list[i].dimlist.size() == dimno)
                   		 return &(fnptr->param_list[i]);
            	}
            	else
            		 return &(fnptr->param_list[i]);
            }
    }
   
    return NULL;

}

//searches variable in var_list of a function
list_var* search_var(string var_name,entry* fnptr,int level)
{
	int max_level=0;
	list_var *temp=NULL;
	if(fnptr == NULL)
		return NULL;
	for(int i=0; i<fnptr->var_list.size(); i++)
	{
		if(fnptr->var_list[i].name == var_name)
		{
			if (max_level < fnptr->var_list[i].level && fnptr->var_list[i].level <= level)
			{
				temp =&(fnptr->var_list[i]);
				max_level=fnptr->var_list[i].level;	
			}
		}
	}
	return temp;
}

//searches variable in var_list of a function
list_var* search_var1(string var_name,var_type vtype, int dimno, entry* fnptr,int level)
{
	int max_level=0;
	list_var *temp=NULL;
	if(fnptr == NULL)
		return NULL;
	for(int i=0; i<fnptr->var_list.size(); i++)
	{
		if(fnptr->var_list[i].name == var_name && vtype==fnptr->var_list[i].vtype)

		{

			if(vtype==ARRAY){
				if(dimno==fnptr->var_list[i].dimlist.size()){
					if (max_level < fnptr->var_list[i].level && fnptr->var_list[i].level <= level)
					{
						temp =&(fnptr->var_list[i]);
						max_level=fnptr->var_list[i].level;	
					}
				}
			}
			else{
			if (max_level < fnptr->var_list[i].level && fnptr->var_list[i].level <= level)
				{
					temp =&(fnptr->var_list[i]);
					max_level=fnptr->var_list[i].level;	
				}
			}
		}
	}
	return temp;
}

list_var* search_global_var(vector<variable> global_table, string var_name)
{
	list_var *temp=NULL;
	for(int i=0; i<global_table.size(); i++)
	{
		if(global_table[i].name == (var_name))
		{
			temp = &global_table[i];
			return temp;
		}
	}
	return temp;
}

list_var* search_global_var1(string param_name,var_type vtype, int dimno,vector<variable> *global_table)
{

	for(int i=0; i<(*global_table).size(); i++)
    {
            if((*global_table)[i].name == param_name  && vtype==(*global_table)[i].vtype)
            {
            	if(vtype==ARRAY){
            		if((*global_table)[i].dimlist.size() == dimno)
                   		 return &((*global_table)[i]);
            	}
            	else
            		 return &((*global_table)[i]);
            }
    }
   
    return NULL;

}

list_var* search_struct_in_global(string param_name,vector<variable> *global_table)
{

	for(int i=0; i<(*global_table).size(); i++)
    {
            if((*global_table)[i].name == param_name  && (*global_table)[i].dtype == STRUCT1)
            {
            		 return &((*global_table)[i]);
            }
    }
   
    return NULL;

}

list_var* search_struct_in_func_table(string param_name,entry *fnptr, int level)
{
	int max_level=0;
	list_var *temp=NULL;
	if(fnptr == NULL || level == 0)
		return NULL;
	for(int i=0; i<fnptr->var_list.size(); i++)
	{
		if(fnptr->var_list[i].name == param_name )

		{
			if (max_level < fnptr->var_list[i].level && fnptr->var_list[i].level <= level)
			{
				temp =&(fnptr->var_list[i]);
				max_level=fnptr->var_list[i].level;	
			}
		}
	}
	if(temp == NULL)
	{
		for(int i=0; i<fnptr->param_list.size(); i++)
    {
            if(fnptr->param_list[i].name == param_name )
            {
            	return &(fnptr->param_list[i]);
            }
    }
	}
	return temp;

}


//make a new entry in the function table
entry *enter_function(string name, data_type type)
{
	entry *new_entry = new entry();
	new_entry->func_name=name;
	new_entry->func_type=type;
	
	return new_entry;
}



//to enter a parameter of a function
void enter_param(string name, data_type type, entry* fnptr)
{
	if(fnptr == NULL)
	{	
		cout << "ERROR: Function Pointer not defined. No parameter can be added.\n";		
		return;
	}

	list_var *new_param = new list_var();
	new_param->name=name;
	new_param->dtype=type;				
	new_param->level=1;

	fnptr->param_list.push_back(*new_param);
}




//to enter vardiables of a function
void enter_var(string name, data_type type,int level ,entry* fnptr)
{
	if(fnptr == NULL)
	{	
		cout << "ERROR: Function Pointer not defined. No variable can be added.\n";		
		return;
	}
	list_var *new_param = new list_var();
	new_param->name=name;
	new_param->dtype=type;	
	new_param->level=level;

	fnptr->var_list.push_back(*new_param);
}





///patch types
void patch_type(std::vector<list_var> variable_list,data_type type, int level)
{
        vector <list_var>::iterator it;
        for (it = variable_list.begin(); it != variable_list.end(); ++it) {
            if(it->level==level)
            	it->dtype=type;
        }
}



///delete the local var_list of a fucntion when u det out of the scope
void delete_var_list(entry *fnptr,int level)
{
	if(fnptr == NULL)
	{	
		cout << "ERROR: Function Pointer not defined. Variable_list is not deleted.\n";		
		return;
	}
	cout<<fnptr->func_name<<endl;
	for (int i=0;i<fnptr->var_list.size();i++)
	{
		if(fnptr->var_list[i].level == level)
		{
			fnptr->var_list.erase(fnptr->var_list.begin()+i);
		}
	}
	
}



//check if type of variable during function call matches declarations
int check_param_type(entry *fnptr,int pos,data_type type )
{
	if(fnptr == NULL)
	{	
		cout << "ERROR: Function Pointer not defined. Variable and parameter can not be matched.\n";		
		return 0;
	}
	vector<list_var>:: iterator it;
	int count = 1;
	for (it=fnptr->param_list.begin(); it != fnptr->param_list.end();++it)
	{
		if(count == pos && it->dtype==type )
		{
			return 1;
		}
		count++;
	}

	return 0;
}



//to check if the two data types can be type casted
int coercible(data_type expr1,data_type expr2)
{
         if(expr1==expr2 && expr1!=NONE && expr1!=ERROR)
                return 1;
        if((expr1==INT1&&expr2==FLOAT1)||(expr1==FLOAT1&&expr2==INT1)||(expr1==INT1&&expr2==CHAR1)||(expr1==CHAR1&&expr2==INT1))
        {
        	return 1;
        }
        return 0;
}




//to check if datatypes are compatible for Arithmetic operations
int comapatible_arithop(data_type a,data_type b){
	if(a==b)
		return 1;
	if((a==INT1 || a==FLOAT1) && (b==INT1 || b==FLOAT1))
		return 1;
	return 0;
}



//to check of they are valid for prod. like E1 -> E2 + E3
data_type compare_type(data_type a, data_type b){
	if(a==INT1 && b==FLOAT1)
		return b;
	if(a==FLOAT1 && b==INT1)
		return a;
	if(a==FLOAT1 && b==FLOAT1)
		return a;
	if(a==INT1 && b==INT1)
		return a;
	return ERROR;
}



void  print_dtype(int a){
	if(a==0)
		cout<<"INT1";
	if(a==1)
		cout<<"FLOAT1";
	if(a==2)
		cout<<"CHAR1";
	if(a==3)
		cout<<"BOOL1";
	if(a==4)
		cout<<"VOID1";
	if(a==5)
		cout<<"STRUCT1";
	if(a==6)
		cout<<"NONE";
	if(a==7)
		cout<<"ERROR"; 
}



void print_vtype(int a){

	if(a==0)
		cout<<"SIMPLE" ; 
	if(a==1)
		cout<<"ARRAY";	
}



void print_global_table(vector<variable> *global_table)
{
	cout << "size of global table is :- " << (*global_table).size() << endl;
	for( int i=0; i<(*global_table).size(); i++)
	{
		cout << (*global_table)[i].name <<"\t";
		print_dtype((*global_table)[i].dtype) ;
		cout<< "\t";
		print_vtype((*global_table)[i].vtype);
		cout << "\n" ;
	}

}


void print_function_table(vector<entry> function_table)
{
	for( int i=0; i<function_table.size(); i++)
	{
		cout << function_table[i].func_name <<"\t"<< function_table[i].func_type << "\t" << function_table[i].num_param << "\n" ;
		cout<<"Parameters:";
		for(int j=0;j<function_table[i].param_list.size();j++)
			cout<<function_table[i].param_list[j].name<<" ";
		cout<<"\n Variables:";
		for(int j=0;j<function_table[i].var_list.size();j++)
			cout<<function_table[i].var_list[j].name<<" " <<function_table[i].var_list[j].dtype<<"      ";

	}
	cout << "\nfunction_table Printed\n";	
}

void print_quadruples(vector<string * > quadruples){

	for(int i=0;i<quadruples.size();i++)
		cout<<i<<". "<<*(quadruples[i])<<endl;

}


void back_patch(vector<int> list, int quad_number ,vector<string *> *quadruples ){
		ostringstream Convert;
		Convert<<quad_number;
		string quad=Convert.str();
		for(int i=0;i<(list).size();i++){
			(*quadruples)[list[i]]->append(" "+quad);
		}
}



vector<int> merge(vector<int> list1, vector<int> list2){
	vector<int> merged;
	for(int i=0;i<list1.size(); i++)
		merged.push_back(list1[i]);
	for(int i=0;i<list2.size(); i++)
		merged.push_back(list2[i]);
	return merged;
}


void gen(int next_quad , vector<string *> *quadruples ,string str){
		string * s=new string;
		*s=str;
		(*quadruples).insert((*quadruples).begin() + next_quad,s);
}





int newtemp( data_type dtype, vector<variable> * global_table ,int scope){
	ostringstream Convert;
	Convert<<temp_count;
	temp_count++;

	string s="T" + Convert.str();

	variable k(s,dtype,SIMPLE,scope);
	k.val.a=-1;

	(*global_table).push_back(k);

	return (* global_table).size() -1;


}

int getindex(list_var * v, vector<variable > *global_table){
	for(int i=0;i<(*global_table).size();i++){
		if(v->name == (*global_table)[i].name)
			return i;
	}

	return -1;
}





int size(data_type d){
	if(d==INT1)
		return 4;
	if(d==FLOAT1)
		return 8;
	if(d==CHAR1)
		return 1;

}
